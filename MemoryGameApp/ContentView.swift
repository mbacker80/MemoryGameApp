//
//  ContentView.swift
//  MemoryGameApp
//
//  Created by James Jolly on 3/6/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        MemoryGameView()
    }
}

#Preview {
    ContentView()
}

struct Card: Identifiable {
    let id = UUID()
    let content: String
    var isFlipped = false
    var isMatched = false
}

class MemoryGameViewModel: ObservableObject {
    @Published var cards: [Card] = []
    @Published var score = 0
    @Published var matches = 0
    @Published var attempts = 0
    private var selectedIndices: [Int] = []
    
    var isGameover: Bool {
        return matches == cards.count / 2
    }
    
    init() {
        resetGame()
    }
    
    func resetGame() {
        let emojis = ["🍎", "🍌", "🍒", "🍇", "🥝", "🍉"]
        let newCards = (emojis + emojis).shuffled().map {Card(content:$0)}
        
        withAnimation(.easeInOut(duration: 0.1)) {
            self.cards.indices.forEach { self.cards[$0].isFlipped = false }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let shuffledCards = newCards.shuffled()
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7, blendDuration: 0.5)) {
                self.cards = shuffledCards
            }
        }
        
        self.selectedIndices.removeAll()
        self.score = 0
        self.attempts = 0
        self.matches = 0
        
    }
    
    func selectCard(_ index: Int) {
        guard !cards[index].isMatched, !cards[index].isFlipped else {return}
        cards[index].isFlipped = true
        selectedIndices.append(index)
        
        if selectedIndices.count == 2 {
            attempts += 1
            checkForMatch()
        }
    }
    
    private func checkForMatch() {
        let firstIndex = selectedIndices[0]
        let secondIndex = selectedIndices[1]
        
        if cards[firstIndex].content == cards[secondIndex].content {
            cards[firstIndex].isMatched = true
            cards[secondIndex].isMatched = true
            score += 2
            matches += 1
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.cards[firstIndex].isFlipped = false
                self.cards[secondIndex].isFlipped = false
                self.score -= 1
                if (self.score < 0) {
                    self.score = 0
                }
            }
        }
        selectedIndices.removeAll()
    }
}

struct MemoryGameView: View {
    @StateObject private var viewModel = MemoryGameViewModel()
    
    let columns = Array(repeating: GridItem(.flexible()), count: 4)
    
    var body: some View {
        VStack {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(viewModel.cards.indices, id: \ .self) {index in
                    CardView(card: viewModel.cards[index])
                        .onTapGesture { viewModel.selectCard(index) }
                }
            }
            .padding()
            
            HStack {
                Text("    Score: \(viewModel.score)")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("Moves: \(viewModel.attempts)    ")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            
            Button("New Game Shuffle") {
                viewModel.resetGame()
            }
            
            if viewModel.isGameover {
                Text("Game Over!")
                    .font(.title)
                    .foregroundColor(.green)
                    .padding()
            }
            
            //.padding()
        }
    }
}

struct CardView: View {
    let card: Card
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(card.isFlipped || card.isMatched ? Color.white : Color.blue)
                .frame(height: 120)
                .overlay(
                    
                    Group {
                        if card.isFlipped || card.isMatched {
                            Text(card.content)
                                .font(.largeTitle)
                        } else {
                            Text("?")
                                .font(.largeTitle)
                                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                        }
                    }
                    
                )
                .rotation3DEffect(
                    .degrees(card.isFlipped || card.isMatched ? 0 : 180),
                    axis: (x: 0, y: 1, z: 0)
                )
                .animation(.easeInOut(duration: 0.5), value: card.isFlipped)
        }
    }
}


