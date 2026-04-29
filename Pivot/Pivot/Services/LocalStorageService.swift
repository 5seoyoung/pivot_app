import Foundation
import SwiftData

@MainActor
final class LocalStorageService {
    static let shared = LocalStorageService()
    private init() {}

    func setupDefaultProfileIfNeeded(in context: ModelContext) {
        guard (try? context.fetch(FetchDescriptor<PatientProfile>()))?.isEmpty ?? true else { return }
        context.insert(PatientProfile())
        try? context.save()
    }

    func latestROM(in context: ModelContext) -> ROMData? {
        var descriptor = FetchDescriptor<ROMData>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    func painRecords(lastDays days: Int, in context: ModelContext) -> [PainRecord] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: .now) ?? .now
        let descriptor = FetchDescriptor<PainRecord>(
            predicate: #Predicate { $0.date >= cutoff },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func hasTodayPainRecord(in context: ModelContext) -> Bool {
        let start = Calendar.current.startOfDay(for: .now)
        let descriptor = FetchDescriptor<PainRecord>(
            predicate: #Predicate { $0.date >= start }
        )
        return ((try? context.fetch(descriptor))?.count ?? 0) > 0
    }
}
