package main

import (
	"bufio"
	"fmt"
	"math/rand"
	"net"
	"sort"
	"strings"
	"sync"
	"time"
)

type Player struct {
	conn           net.Conn
	x, y           int
	symbol         string
	score          int
	respawning     bool
	lastDirectionX int
	lastDirectionY int
}

type Projectile struct {
	x, y   int
	dx, dy int
	owner  *Player
}

type Game struct {
	players     map[net.Conn]*Player
	projectiles []*Projectile
	byteCounter int64
	mu          sync.Mutex
	updated     bool
}

func (g *Game) handleConnection(conn net.Conn) {
	defer conn.Close()
	player := &Player{conn: conn, x: rand.Intn(40), y: rand.Intn(20), symbol: "X"}
	g.players[conn] = player
	g.broadcastGrid()

	reader := bufio.NewReader(conn)
	for {
		message, err := reader.ReadString('\n')
		if err != nil {
			delete(g.players, conn)
			return
		}
		g.handleCommand(player, strings.TrimSpace(message))
	}
}

func (g *Game) handleCommand(player *Player, command string) {
	if player.respawning {
		return
	}

	previousX, previousY := player.x, player.y
	switch command {
	case "k":
		if player.y > 0 {
			player.y--
			player.lastDirectionX, player.lastDirectionY = 0, -1
		}
	case "j":
		if player.y < 19 {
			player.y++
			player.lastDirectionX, player.lastDirectionY = 0, 1
		}
	case "h":
		if player.x > 0 {
			player.x--
			player.lastDirectionX, player.lastDirectionY = -1, 0
		}
	case "l":
		if player.x < 39 {
			player.x++
			player.lastDirectionX, player.lastDirectionY = 1, 0
		}
	case "a":
		g.addProjectile(player)
	}
	if player.x != previousX || player.y != previousY {
		g.updated = true
	}
}

func (g *Game) addProjectile(player *Player) {
	projectile := &Projectile{
		x:     player.x,
		y:     player.y,
		dx:    player.lastDirectionX,
		dy:    player.lastDirectionY,
		owner: player,
	}
	g.projectiles = append(g.projectiles, projectile)
	g.updated = true
}

func (g *Game) respawnPlayer(player *Player) {
	time.Sleep(2 * time.Second)
	player.x, player.y = rand.Intn(40), rand.Intn(20)
	player.respawning = false
	g.mu.Lock()
	g.updated = true
	g.mu.Unlock()
}

func (g *Game) moveProjectiles() {
	var remainingProjectiles []*Projectile
	projectilesUpdated := false

	for _, p := range g.projectiles {
		p.x += p.dx
		p.y += p.dy

		collided := false
		for _, player := range g.players {
			if !player.respawning && p.x == player.x && p.y == player.y {

				if p.owner != nil {
					p.owner.score += 1
				}
				player.score -= 1
				player.respawning = true
				go g.respawnPlayer(player)

				collided = true
				break
			}
		}

		if p.x < 0 || p.x >= 40 || p.y < 0 || p.y >= 20 || collided {
			projectilesUpdated = true
			continue
		}

		remainingProjectiles = append(remainingProjectiles, p)
		projectilesUpdated = true
	}

	g.projectiles = remainingProjectiles
	if projectilesUpdated {
		g.updated = true
	}
}

func (g *Game) drawGrid() string {
	grid := ""
	for y := 0; y < 20; y++ {
		for x := 0; x < 40; x++ {
			found := false
			for _, player := range g.players {
				if !player.respawning && player.x == x && player.y == y {
					grid += player.symbol
					found = true
					break
				}
			}
			if !found {
				for _, projectile := range g.projectiles {
					if projectile.x == x && projectile.y == y {
						grid += "*"
						found = true
						break
					}
				}
			}
			if !found {
				grid += "."
			}
		}
		grid += "\n"
	}

	grid += "\nScoreboard:\n"
	players := make([]*Player, 0, len(g.players))
	for _, player := range g.players {
		players = append(players, player)
	}
	sort.Slice(players, func(i, j int) bool {
		return players[i].score > players[j].score
	})
	for _, player := range players {
		grid += fmt.Sprintf("%s: %d\n", player.symbol, player.score)
	}

	return grid
}

func (g *Game) broadcastGrid() {
	if !g.updated {
		return
	}
	fmt.Printf("Bytes sent: %d\n", g.byteCounter)

	grid := g.drawGrid()
	for _, player := range g.players {
		bytesSent, err := player.conn.Write([]byte(grid))
		if err == nil {
			g.mu.Lock()
			g.byteCounter += int64(bytesSent)
			g.mu.Unlock()
		} else {
			fmt.Println("Error sending data to player:", err)
		}
	}

	g.updated = false
}

func (g *Game) startGameLoop() {
	ticker := time.NewTicker(100 * time.Millisecond)
	defer ticker.Stop()
	for {
		select {
		case <-ticker.C:
			g.moveProjectiles()
			g.broadcastGrid()
		}
	}
}

func main() {
	game := Game{
		players:     make(map[net.Conn]*Player),
		projectiles: make([]*Projectile, 0),
	}
	listener, err := net.Listen("tcp", ":9000")
	if err != nil {
		fmt.Println("Error starting server:", err)
		return
	}
	defer listener.Close()
	fmt.Println("Server is listening on port 9000")
	go game.startGameLoop()

	for {
		conn, err := listener.Accept()

		if err != nil {
			fmt.Println("Error accepting connection:", err)
			continue
		}
		go game.handleConnection(conn)
	}
}
