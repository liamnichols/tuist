import Foundation
import Mockable
import struct TSCUtility.Version
import TuistCore
import TuistHasher
import TuistSupport
import TuistSupportTesting
import XcodeGraph
import XCTest

@testable import TuistCache

final class CacheGraphContentHasherTests: TuistUnitTestCase {
    private var graphContentHasher: MockGraphContentHashing!
    private var contentHasher: MockContentHashing!
    private var defaultConfigurationFetcher: MockDefaultConfigurationFetching!
    private var subject: CacheGraphContentHasher!

    override func setUp() {
        super.setUp()

        graphContentHasher = .init()
        contentHasher = .init()
        defaultConfigurationFetcher = MockDefaultConfigurationFetching()

        subject = CacheGraphContentHasher(
            graphContentHasher: graphContentHasher,
            contentHasher: contentHasher,
            versionFetcher: CacheVersionFetcher(),
            defaultConfigurationFetcher: defaultConfigurationFetcher,
            xcodeController: xcodeController,
            swiftVersionProvider: swiftVersionProvider
        )

        given(xcodeController)
            .selectedVersion()
            .willReturn(Version(15, 0, 0))
    }

    override func tearDown() {
        graphContentHasher = nil
        contentHasher = nil
        defaultConfigurationFetcher = nil
        subject = nil
        super.tearDown()
    }

    func test_contentHashes_when_no_excluded_targets_all_hashes_are_computed() async throws {
        // Given
        let includedTarget = GraphTarget(
            path: "/Project/Path",
            target: Target.test(name: "Included", product: .framework),
            project: Project.test()
        )
        given(graphContentHasher)
            .contentHashes(
                for: .any,
                include: .any,
                destination: .any,
                additionalStrings: .any
            )
            .willReturn([:])
        given(defaultConfigurationFetcher)
            .fetch(configuration: .any, defaultConfiguration: .any, graph: .any)
            .willReturn("Debug")
        given(swiftVersionProvider).swiftlangVersion().willReturn("5.10.0")

        // When
        _ = try await subject.contentHashes(
            for: Graph.test(),
            configuration: "Debug",
            defaultConfiguration: nil,
            excludedTargets: [],
            destination: nil
        )

        // Then
        verify(graphContentHasher)
            .contentHashes(
                for: .any,
                include: .matching { filter in
                    filter(includedTarget)
                },
                destination: .any,
                additionalStrings: .any
            )
            .called(1)
    }

    func test_contentHashes_when_excluded_targets_excluded_hashes_are_not_computed() async throws {
        // Given
        let excludedTarget = GraphTarget(
            path: "/Project/Path",
            target: Target.test(name: "Excluded", product: .framework),
            project: Project.test()
        )
        let includedTarget = GraphTarget(
            path: "/Project/Path",
            target: Target.test(name: "Included", product: .framework),
            project: Project.test()
        )
        given(graphContentHasher)
            .contentHashes(
                for: .any,
                include: .any,
                destination: .any,
                additionalStrings: .any
            )
            .willReturn([:])
        given(defaultConfigurationFetcher)
            .fetch(configuration: .any, defaultConfiguration: .any, graph: .any)
            .willReturn("Debug")
        given(swiftVersionProvider).swiftlangVersion().willReturn("5.10.0")

        // When
        _ = try await subject.contentHashes(
            for: Graph.test(),
            configuration: "Debug",
            defaultConfiguration: nil,
            excludedTargets: ["Excluded"],
            destination: nil
        )

        // Then
        verify(graphContentHasher)
            .contentHashes(
                for: .any,
                include: .matching { filter in
                    filter(includedTarget) && !filter(excludedTarget)
                },
                destination: .any,
                additionalStrings: .any
            )
            .called(1)
    }

    func test_contentHashes_when_excluded_targets_resources_hashes_are_not_computed() async throws {
        // Given
        let project = Project.test()

        let excludedTarget = GraphTarget(
            path: "/Project/Path",
            target: Target.test(name: "Excluded", product: .framework),
            project: project
        )
        let excludedTargetResource = GraphTarget(
            path: "/Project/Path",
            target: Target.test(name: "\(project.name)_Excluded", product: .bundle),
            project: project
        )
        let includedTarget = GraphTarget(
            path: "/Project/Path",
            target: Target.test(name: "Included", product: .framework),
            project: Project.test()
        )
        given(graphContentHasher)
            .contentHashes(
                for: .any,
                include: .any,
                destination: .any,
                additionalStrings: .any
            )
            .willReturn([:])
        given(defaultConfigurationFetcher)
            .fetch(configuration: .any, defaultConfiguration: .any, graph: .any)
            .willReturn("Debug")
        given(swiftVersionProvider).swiftlangVersion().willReturn("5.10.0")

        // When
        _ = try await subject.contentHashes(
            for: Graph.test(),
            configuration: "Debug",
            defaultConfiguration: nil,
            excludedTargets: ["Excluded"],
            destination: nil
        )

        // Then
        verify(graphContentHasher)
            .contentHashes(
                for: .any,
                include: .matching { filter in
                    filter(includedTarget) && !filter(excludedTarget) && !filter(excludedTargetResource)
                },
                destination: .any,
                additionalStrings: .any
            )
            .called(1)
    }
}
