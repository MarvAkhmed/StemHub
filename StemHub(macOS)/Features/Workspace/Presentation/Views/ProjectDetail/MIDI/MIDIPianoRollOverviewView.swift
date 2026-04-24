//
//  MIDIPianoRollOverviewView.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 06.04.2026.
//

import SwiftUI

struct MIDIPianoRollOverviewView: View {
    let notes: [MIDINoteEvent]
    let totalBeats: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.black.opacity(0.22))

                grid(in: geometry.size)

                ForEach(notes) { note in
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.78, green: 0.60, blue: 0.98),
                                    Color(red: 0.48, green: 0.35, blue: 0.90)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: noteWidth(note, totalWidth: geometry.size.width),
                            height: 10
                        )
                        .offset(
                            x: noteX(note, totalWidth: geometry.size.width),
                            y: noteY(note, totalHeight: geometry.size.height)
                        )
                }
            }
        }
        .frame(height: 220)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

private extension MIDIPianoRollOverviewView {
    func grid(in size: CGSize) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(0..<8, id: \.self) { row in
                Rectangle()
                    .fill(row.isMultiple(of: 2) ? Color.white.opacity(0.02) : .clear)
                    .frame(height: size.height / 8)
                    .offset(y: CGFloat(row) * size.height / 8)
            }

            ForEach(0..<beatColumns, id: \.self) { index in
                Rectangle()
                    .fill(index.isMultiple(of: 4) ? Color.white.opacity(0.10) : Color.white.opacity(0.04))
                    .frame(width: 1, height: size.height)
                    .offset(x: CGFloat(index) * size.width / CGFloat(beatColumns))
            }
        }
    }

    var beatColumns: Int {
        max(Int(ceil(max(totalBeats, 8))), 8)
    }

    func noteX(_ note: MIDINoteEvent, totalWidth: CGFloat) -> CGFloat {
        guard totalBeats > 0 else { return 0 }
        return CGFloat(note.startBeat / totalBeats) * totalWidth
    }

    func noteWidth(_ note: MIDINoteEvent, totalWidth: CGFloat) -> CGFloat {
        guard totalBeats > 0 else { return 16 }
        return max(CGFloat(note.durationBeats / totalBeats) * totalWidth, 12)
    }

    func noteY(_ note: MIDINoteEvent, totalHeight: CGFloat) -> CGFloat {
        let pitch = Int(note.noteNumber)
        let normalized = Double(max(0, min(127 - pitch, 127))) / 127
        return CGFloat(normalized) * (totalHeight - 14)
    }
}
