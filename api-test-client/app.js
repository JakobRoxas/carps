const form = document.querySelector("#request-form");
const baseUrlInput = document.querySelector("#base-url");
const methodInput = document.querySelector("#method");
const pathInput = document.querySelector("#path");
const bodyInput = document.querySelector("#body");
const statusOutput = document.querySelector("#request-status");
const responseOutput = document.querySelector("#response-output");

function formatResponse(value) {
  if (typeof value === "string") {
    try {
      return JSON.stringify(JSON.parse(value), null, 2);
    } catch {
      return value;
    }
  }

  return JSON.stringify(value, null, 2);
}

function setStatus(message, state = "") {
  statusOutput.textContent = message;
  statusOutput.className = `status ${state}`;
}

form.addEventListener("submit", async (event) => {
  event.preventDefault();

  const method = methodInput.value;
  const baseUrl = baseUrlInput.value.trim().replace(/\/+$/, "");
  const path = pathInput.value.trim();
  const url = `${baseUrl}/${path.replace(/^\/+/, "")}`;
  const rawBody = bodyInput.value.trim();

  let body;
  if (rawBody) {
    try {
      body = JSON.stringify(JSON.parse(rawBody));
    } catch {
      setStatus("Invalid JSON", "error");
      responseOutput.textContent = "The request body must contain valid JSON.";
      return;
    }
  }

  setStatus("Loading...", "loading");
  responseOutput.textContent = "";
  const startedAt = performance.now();

  try {
    const response = await fetch(url, {
      method,
      headers: body ? { "Content-Type": "application/json" } : {},
      body,
    });
    const responseText = await response.text();
    const duration = Math.round(performance.now() - startedAt);
    const state = response.ok ? "success" : "error";

    setStatus(`${response.status} ${response.statusText} - ${duration} ms`, state);
    responseOutput.textContent = responseText
      ? formatResponse(responseText)
      : "(empty response)";
  } catch (error) {
    const duration = Math.round(performance.now() - startedAt);
    setStatus(`Request failed - ${duration} ms`, "error");
    responseOutput.textContent =
      `${error.message}\n\nCheck that the backend is running and CORS is enabled.`;
  }
});
