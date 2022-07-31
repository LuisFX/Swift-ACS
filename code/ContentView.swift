import SwiftUI

struct ContentView: View {
    @State var currentTab: Tab = .home

    var body: some View {
        NavigationView {
            TabView(selection: $currentTab) {
                ForEach(Tab.allCases) { tab in
                    tab.presentingView
                        .tabItem { tab.tabItem }
                        .tag(tab)
                }
            }
            .navigationBarTitle(currentTab.name, displayMode: .inline)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}