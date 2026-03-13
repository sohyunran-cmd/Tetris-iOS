import SwiftUI
import Combine

// 方块类型
enum BlockShape: CaseIterable {
    case I, O, T, L, J, S, Z
}

// 单个格子
struct Block: Identifiable {
    let id = UUID()
    var x: Int
    var y: Int
    var color: Color
}

// 单个方块组
struct Tetromino {
    var blocks: [Block]
    var type: BlockShape
    
    mutating func moveBy(x: Int, y: Int) {
        for i in blocks.indices {
            blocks[i].x += x
            blocks[i].y += y
        }
    }
    
    mutating func rotate(around pivot: Block) {
        for i in blocks.indices {
            let dx = blocks[i].x - pivot.x
            let dy = blocks[i].y - pivot.y
            blocks[i].x = pivot.x - dy
            blocks[i].y = pivot.y + dx
        }
    }
}

struct GameView: View {
    let gridWidth = 10
    let gridHeight = 20
    let blockSize: CGFloat = 25
    
    @State var landedBlocks: [Block] = []
    @State var currentPiece: Tetromino!
    @State var gameTimer: Timer.TimerPublisher?
    @State var cancellable: Cancellable?
    
    let colors: [BlockShape: Color] = [
        .I: .cyan, .O: .yellow, .T: .purple,
        .L: .orange, .J: .blue, .S: .green, .Z: .red
    ]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 2) {
                ForEach(0..<gridHeight, id: \.self) { y in
                    HStack(spacing: 2) {
                        ForEach(0..<gridWidth, id: \.self) { x in
                            Rectangle()
                                .fill(cellColor(at: x, y))
                                .frame(width: blockSize, height: blockSize)
                        }
                    }
                }
            }
            
            VStack {
                Spacer()
                HStack(spacing: 20) {
                    Button("左") { moveLeft() }
                    Button("下") { moveDown() }
                    Button("右") { moveRight() }
                    Button("转") { rotate() }
                }
                .foregroundColor(.white)
                .padding()
            }
        }
        .onAppear(perform: startGame)
    }
}

// MARK: - 游戏逻辑
extension GameView {
    func startGame() {
        spawnNewPiece()
        gameTimer = Timer.publish(every: 0.7, on: .main, in: .common)
        cancellable = gameTimer?.connect()
        NotificationCenter.default.addObserver(
            forName: .init("TimerTick"),
            object: nil,
            queue: .main
        ) { _ in
            moveDown()
        }
    }
    
    func spawnNewPiece() {
        let type = BlockShape.allCases.randomElement()!
        let color = colors[type]!
        var blocks = [Block]()
        
        let centerX = gridWidth / 2 - 1
        switch type {
        case .I:
            blocks = [
                Block(x: centerX-1, y: 0, color: color),
                Block(x: centerX,   y: 0, color: color),
                Block(x: centerX+1, y: 0, color: color),
                Block(x: centerX+2, y: 0, color: color)
            ]
        case .O:
            blocks = [
                Block(x: centerX, y: 0, color: color),
                Block(x: centerX+1,y:0,color: color),
                Block(x: centerX, y:1,color: color),
                Block(x: centerX+1,y:1,color: color)
            ]
        default:
            blocks = [
                Block(x: centerX, y:0, color: color),
                Block(x: centerX-1,y:0,color: color),
                Block(x: centerX+1,y:0,color: color),
                Block(x: centerX, y:1,color: color)
            ]
        }
        
        currentPiece = Tetromino(blocks: blocks, type: type)
    }
    
    func cellColor(at x: Int, _ y: Int) -> Color {
        if let b = currentPiece.blocks.first(where: { $0.x == x && $0.y == y }) {
            return b.color
        }
        if let b = landedBlocks.first(where: { $0.x == x && $0.y == y }) {
            return b.color
        }
        return Color.gray.opacity(0.2)
    }
    
    func moveDown() {
        var copy = currentPiece!
        copy.moveBy(x: 0, y: 1)
        
        if isValid(copy) {
            currentPiece = copy
        } else {
            lockPiece()
        }
    }
    
    func moveLeft() {
        var copy = currentPiece!
        copy.moveBy(x: -1, y: 0)
        if isValid(copy) { currentPiece = copy }
    }
    
    func moveRight() {
        var copy = currentPiece!
        copy.moveBy(x: 1, y: 0)
        if isValid(copy) { currentPiece = copy }
    }
    
    func rotate() {
        guard !currentPiece.blocks.isEmpty else { return }
        var copy = currentPiece!
        let pivot = copy.blocks[0]
        copy.rotate(around: pivot)
        if isValid(copy) { currentPiece = copy }
    }
    
    func isValid(_ piece: Tetromino) -> Bool {
        for b in piece.blocks {
            if b.x < 0 || b.x >= gridWidth || b.y >= gridHeight {
                return false
            }
            if landedBlocks.contains(where: { $0.x == b.x && $0.y == b.y }) {
                return false
            }
        }
        return true
    }
    
    func lockPiece() {
        landedBlocks.append(contentsOf: currentPiece.blocks)
        clearLines()
        spawnNewPiece()
    }
    
    func clearLines() {
        for y in (0..<gridHeight).reversed() {
            let count = landedBlocks.filter { $0.y == y }.count
            if count == gridWidth {
                landedBlocks.removeAll { $0.y == y }
                for i in landedBlocks.indices where landedBlocks[i].y < y {
                    landedBlocks[i].y += 1
                }
            }
        }
    }
}

struct ContentView: View {
    var body: some View {
        GameView()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
