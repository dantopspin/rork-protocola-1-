import Foundation

nonisolated enum TrackingRoute: Hashable { case protocolDetail(UUID), vialDetail(UUID), logDetail(UUID) }
