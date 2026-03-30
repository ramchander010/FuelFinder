import SwiftUI
import MapKit

struct StationListSheet: View {
    @ObservedObject var vm: MainViewModel
    var body: some View {
        VStack(spacing: 0) {
            // Sheet header
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("⛽  Petrol Pumps")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(hex: "1A1A2E"))
                    Text("\(vm.stations.count) pumps  •  Sorted ₹ Low → High")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: "2E7D32"))
                }
                Spacer()
                Button { vm.showStationList = false} label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(hex: "6B7280"))
                        .frame(width: 32, height: 32)
                        .background(Color(hex: "F0F0F0"))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 20).padding(.top, 6).padding(.bottom, 12)

            Divider()
             ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(vm.stations.enumerated()), id: \.element.id) { i, s in
                        StationCard(
                            station: s,
                            rank: i + 1,
                            onTap: {
                                vm.navigateToStation(s)
                                vm.showStationList = false
                            }

                        )
                    }
                }
                .padding(.bottom, 36)
            
            }
        }
        .background(Color.white)
    }
}

// MARK: - Station Card
struct StationCard: View {
    let station: FuelStation
    let rank: Int
    let onTap: () -> Void
    var onNavigate: (() -> Void)? = nil
    private var accentColor: Color {
        if station.isBestOption ?? false { return Color(hex: "2E7D32") }
        switch station.brand {
        case "Indian Oil": return Color(hex: "E53935")
        case "BPCL":       return Color(hex: "1565C0")
        case "HPCL":       return Color(hex: "2E7D32")
        case "Shell":      return Color(hex: "FFA000")
        case "Reliance":   return Color(hex: "6A1B9A")
        case "Nayara":     return Color(hex: "0277BD")
        default:           return Color(hex: "4361EE")
        }
    }
    var body: some View {
        Button(action: onTap
        ) {
            HStack(spacing: 0) {
                Rectangle().fill(accentColor).frame(width: 5)

                VStack(alignment: .leading, spacing: 0) {
                    if station.isBestOption ?? false {
                        HStack {
                            Text("⭐  BEST OPTION  —  CHEAPEST PRICE")
                                .font(.system(size: 11, weight: .bold)).foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(LinearGradient(colors: [Color(hex: "2E7D32"), Color(hex: "43A047")], startPoint: .leading, endPoint: .trailing))
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(station.name ?? "")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color(hex: "1A1A2E"))
                                .lineLimit(1)
                            Spacer()
                            Text(station.brand ?? "")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color(hex: "6B7280"))
                                .padding(.horizontal, 10).padding(.vertical, 4)
                                .background(Color(hex: "F0F2F5")).cornerRadius(20)
                        }

                        Text(station.address ?? "")
                            .font(.system(size: 12)).foregroundColor(Color(hex: "6B7280")).lineLimit(1)
                        Divider()
                        HStack(alignment: .bottom) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("FUEL PRICE")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(Color(hex: "6B7280")).tracking(1)
                                Text("₹\(String(format: "%.2f", station.price ?? 0.0))/L")
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundColor(station.isBestOption ?? false ? Color(hex: "2E7D32") : Color(hex: "1A237E"))
                            }
                            Spacer()
                            VStack(alignment: .center, spacing: 2) {
                                Text("FROM ROUTE")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(Color(hex: "6B7280")).tracking(0.8)
                                Text("\(String(format: "%.1f", station.distanceFromRoute ?? 0.0)) km")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Color(hex: "1A1A2E"))
                            }
                            Spacer()
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(colors: [Color(hex: "4361EE"), Color(hex: "3A0CA3")], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 44, height: 44)
                                Text("#\(rank)").font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.horizontal, 14).padding(.vertical, 12)
                }
                .background(station.isBestOption ?? false ? Color(hex: "F1FFF4") : Color.white)
            }
        }
        .buttonStyle(.plain)

        Divider().padding(.leading, 5)
    }
}
