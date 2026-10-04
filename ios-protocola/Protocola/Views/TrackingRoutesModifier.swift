import SwiftUI

struct TrackingRoutesModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.navigationDestination(for: TrackingRoute.self) { route in
            switch route {
            case .protocolDetail(let id): ProtocolDetailView(protocolID: id)
            case .vialDetail(let id): VialDetailView(vialID: id)
            case .logDetail(let id): LogDetailView(logID: id)
            }
        }
    }
}

extension View { func trackingRoutes() -> some View { modifier(TrackingRoutesModifier()) } }
