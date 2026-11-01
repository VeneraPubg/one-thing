import WidgetKit
import SwiftUI

/// Main app side: bridges widget taps back into the running Flutter app.
/// Registered in AppDelegate. Calls WidgetCenter to reload timelines
/// whenever the Flutter side updates the shared data.
@main
struct OneThingWidgetBundle: WidgetBundle {
    var body: some Widget {
        OneThingWidget()
    }
}
