import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            MonthlySpendingView()
                .tabItem {
                    Label("지출", systemImage: "chart.bar.fill")
                }

            AddCashView()
                .tabItem {
                    Label("현금 입력", systemImage: "plus.circle.fill")
                }

            SettingsView()
                .tabItem {
                    Label("설정", systemImage: "gearshape.fill")
                }
        }
    }
}
