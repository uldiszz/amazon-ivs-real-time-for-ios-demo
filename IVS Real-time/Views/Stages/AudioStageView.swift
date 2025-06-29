//
//  AudioStageView.swift
//  IVS Real-time
//
//  Created by Uldis Zingis on 28/03/2023.
//

import SwiftUI

struct AudioStageView: View {
    @EnvironmentObject var appModel: AppModel
    @StateObject var stage: Stage
    @State var stageSeatRows: [StageSeatRow] = []

    var body: some View {
        ZStack(alignment: .top) {
            VStack {
                ForEach(stageSeatRows) { row in
                    HStack {
                        ForEach(row.seats) { seat in
                            let participantId = stage.participantIdForSeat(at: seat.index)
                            if participantId.isEmpty {
                                EmptySeat(seat: seat, stage: stage)
                            } else {
                                if let participant = appModel.stageModel.dataForParticipant(participantId) {
                                    TakenSeat(seat: seat, user: participant)
                                } else {
                                    SeatView(seat: seat, content: {
                                        AvatarView(avatar: nil,
                                                   withBorder: true,
                                                   borderColor: .white,
                                                   size: 60)
                                    })
                                }
                            }
                        }
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: 551)
            .offset(y: -120)
        }
        .edgesIgnoringSafeArea(.top)
        .frame(width: UIScreen.main.bounds.width,
               height: UIScreen.main.bounds.height - appModel.activeStageBottomSpace)
        .background(
            Image("AUDIO_STAGE_BG")
                .resizable()
        )
        .cornerRadius(30)
        .overlay {
            StageOverlayView(stage: stage)
        }
        .onAppear {
            setSeats()
        }
    }

    func setSeats() {
        stageSeatRows = []
        var index: Int = 0
        for _ in 0...2 {
            var seats: [StageSeat] = []
            for _ in 0...3 {
                seats.append(StageSeat(index: index,
                                       participantId: stage.participantIdForSeat(at: index)))
                index += 1
            }
            let row = StageSeatRow(seats: seats)
            stageSeatRows.append(row)
            seats = []
        }
    }
}

struct EmptySeat: View {
    @EnvironmentObject var appModel: AppModel
    @ObservedObject var seat: StageSeat
    @ObservedObject var stage: Stage

    var body: some View {
        SeatView(seat: seat, content: {
            if stage.participantIdForSeat(at: seat.index).isEmpty {
                Button {
                    if appModel.user.isHost { return }

                    if appModel.user.isOnStage {
                        appModel.changeSeat(to: seat.index)
                    } else {
                        appModel.publishToAudioStage(inAudioSeat: seat.index)
                    }
                } label: {
                    Image("PlusOutline")
                        .resizable()
                        .frame(width: 40, height: 40)
                }
            } else {
                ProgressView()
            }
        })
    }
}

struct TakenSeat: View {
    @ObservedObject var seat: StageSeat
    @ObservedObject var user: User

    var body: some View {
        SeatView(seat: seat, content: {
            ZStack {
                AvatarView(avatar: user.avatar,
                           withBorder: true,
                           borderColor: user.isSpeaking ? Color("Orange") : .white,
                           size: 60)

                if user.audioMuted {
                    ZStack {
                        Circle()
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .overlay {
                                Image("microphone-slash")
                                    .resizable()
                                    .renderingMode(.template)
                                    .foregroundColor(Color("Red"))
                                    .frame(width: 15, height: 15)
                            }
                    }
                    .offset(x: 15, y: 15)
                }
            }
        })
    }
}

struct SeatView<Content: View>: View {
    @ObservedObject var seat: StageSeat
    let content: Content

    init(seat: StageSeat, @ViewBuilder content: () -> Content) {
        self.seat = seat
        self.content = content()
    }

    var body: some View {
        ZStack {
            content
                .frame(minWidth: 80, minHeight: 94)
                .frame(maxWidth: 130, maxHeight: 133)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .foregroundColor(Color.clear)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white, lineWidth: 1)
                }
                .colorScheme(.light)
        )
    }
}
