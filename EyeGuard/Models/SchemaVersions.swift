import Foundation
import SwiftData

// MARK: - Schema V1

/// Initial schema: BreakSession + DailySummary with no unique constraints.
enum EyeGuardSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] = [BreakSession.self, DailySummary.self]
}

// MARK: - Migration Plan

/// Declares the ordered list of schema versions and migration stages.
/// Add new VersionedSchema types and `MigrationStage` entries here when
/// the data model changes across app releases.
enum EyeGuardMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] = [EyeGuardSchemaV1.self]
    static var stages: [MigrationStage] = []
}
