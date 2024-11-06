const readline = require("readline");
readline.emitKeypressEvents(process.stdin);
process.stdin.setRawMode(true);

const gridWidth = 40;
const gridHeight = 20;

class Player {
  constructor(x, y, symbol, controls) {
    this.x = x;
    this.y = y;
    this.symbol = symbol;
    this.controls = controls;
    this.lastKey = "";
    this.lastKeyTime = 0;
  }

  move(direction) {
    if (direction === "up" && this.y > 0) this.y--;
    if (direction === "down" && this.y < gridHeight - 1) this.y++;
    if (direction === "left" && this.x > 0) this.x--;
    if (direction === "right" && this.x < gridWidth - 1) this.x++;
  }

  canShoot(direction) {
    return Date.now() - this.lastKeyTime < 300 && this.lastKey === direction;
  }
}

class Projectile {
  constructor(x, y, dx, dy) {
    this.x = x;
    this.y = y;
    this.dx = dx;
    this.dy = dy;
  }

  move() {
    this.x += this.dx;
    this.y += this.dy;
  }

  isOutOfBounds() {
    return (
      this.x < 0 || this.x >= gridWidth || this.y < 0 || this.y >= gridHeight
    );
  }
}

class Game {
  constructor() {
    this.players = [
      new Player(1, 1, "X", { up: "w", down: "s", left: "a", right: "d" }),
      new Player(gridWidth - 2, gridHeight - 2, "O", {
        up: "up",
        down: "down",
        left: "left",
        right: "right",
      }),
    ];
    this.projectiles = [];
  }

  drawGrid() {
    console.clear();
    for (let y = 0; y < gridHeight; y++) {
      let row = "";
      for (let x = 0; x < gridWidth; x++) {
        const player = this.players.find((p) => p.x === x && p.y === y);
        const projectile = this.projectiles.find((p) => p.x === x && p.y === y);
        if (player) row += player.symbol;
        else if (projectile) row += "*";
        else row += ".";
      }
      console.log(row);
    }
    console.log(
      "Player 1: WASD keys (double press to shoot) | Player 2: Arrow keys (double press to shoot)"
    );
  }

  addProjectile(player, direction) {
    const speed = 1;
    let dx = 0,
      dy = 0;
    if (direction === "up") dy = -speed;
    if (direction === "down") dy = speed;
    if (direction === "left") dx = -speed;
    if (direction === "right") dx = speed;

    this.projectiles.push(new Projectile(player.x + dx, player.y + dy, dx, dy));
  }

  handlePlayerAction(player, direction) {
    if (player.canShoot(direction)) {
      this.addProjectile(player, direction);
    } else {
      player.move(direction);
    }
    player.lastKey = direction;
    player.lastKeyTime = Date.now();
  }

  moveProjectiles() {
    this.projectiles.forEach((p, index) => {
      p.move();

      if (p.isOutOfBounds()) {
        this.projectiles.splice(index, 1);
      } else {
        this.players.forEach((player, idx) => {
          if (p.x === player.x && p.y === player.y) {
            console.clear();
            console.log(`Player ${idx + 1} was hit! Game over.`);
            process.exit();
          }
        });
      }
    });
  }

  handleKeyPress(key) {
    this.players.forEach((player, idx) => {
      if (key.name === player.controls.up)
        this.handlePlayerAction(player, "up");
      if (key.name === player.controls.down)
        this.handlePlayerAction(player, "down");
      if (key.name === player.controls.left)
        this.handlePlayerAction(player, "left");
      if (key.name === player.controls.right)
        this.handlePlayerAction(player, "right");
    });
  }

  start() {
    this.drawGrid();
    setInterval(() => {
      this.moveProjectiles();
      this.drawGrid();
    }, 100);
  }
}

const game = new Game();
game.start();

process.stdin.on("keypress", (str, key) => {
  if (key.ctrl && key.name === "c") process.exit();
  game.handleKeyPress(key);
});
