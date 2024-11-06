const net = require("net");
const readline = require("readline");

readline.emitKeypressEvents(process.stdin);
process.stdin.setRawMode(true);
process.stdin.on("keypress", (_, key) => handleKeypress(key));

const serverHost = "127.0.0.1";
const serverPort = 9000;

let client;
let reconnecting = false;
let pingInterval;

function startPing() {
  pingInterval = setInterval(() => {
    if (!reconnecting) {
      const pingClient = new net.Socket();
      pingClient.on("error", () => pingClient.destroy());
      pingClient.on("connect", () => {
        console.log("Server is up, attempting to connect...");
        pingClient.destroy();
        attemptConnect();
      });
      pingClient.connect(serverPort, serverHost);
    }
  }, 1000);
}

function attemptConnect() {
  if (reconnecting) return;

  console.log("Attempting to connect...");
  client = new net.Socket();

  client.on("data", (data) => update(data));
  client.on("error", handleConnectionError);
  client.on("close", handleConnectionClose);

  client.connect(serverPort, serverHost, () => {
    console.log("Connected to the server");
    clearInterval(pingInterval);
  });
}

function handleConnectionError(err) {
  console.error("Connection error:", err.message);
  handleReconnection();
}

function handleConnectionClose() {
  console.log("Connection closed");
  handleReconnection();
}

function handleReconnection() {
  if (reconnecting) return;

  reconnecting = true;
  console.log("Reconnecting in 3 seconds...");
  setTimeout(() => {
    reconnecting = false;
    attemptConnect();
  }, 3000);
}

startPing();

function handleKeypress(key) {
  if (key.ctrl && key.name === "c") process.exit();
  if (client.writable) {
    client.write(key.name + "\n");
  }
}

function update(data) {
  console.clear();
  console.log(data.toString());
}
