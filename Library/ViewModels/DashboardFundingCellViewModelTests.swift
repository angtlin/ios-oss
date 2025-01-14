@testable import KsApi
@testable import Library
import Prelude
import ReactiveExtensions
import ReactiveExtensions_TestHelpers
import ReactiveSwift
import XCTest

internal final class DashboardFundingCellViewModelTests: TestCase {
  internal let vm = DashboardFundingCellViewModel()
  internal let backersText = TestObserver<String, Never>()
  internal let cellAccessibilityValue = TestObserver<String, Never>()
  internal let deadlineDateText = TestObserver<String, Never>()
  internal let goalText = TestObserver<String, Never>()
  internal let launchDateText = TestObserver<String, Never>()
  internal let pledgedText = TestObserver<String, Never>()
  internal let project = TestObserver<Project, Never>()
  internal let stats = TestObserver<[ProjectStatsEnvelope.FundingDateStats], Never>()
  internal let timeRemainingSubtitleText = TestObserver<String, Never>()
  internal let timeRemainingTitleText = TestObserver<String, Never>()
  internal let yAxisTickSize = TestObserver<CGFloat, Never>()

  internal override func setUp() {
    super.setUp()
    self.vm.outputs.backersText.observe(self.backersText.observer)
    self.vm.outputs.cellAccessibilityValue.observe(self.cellAccessibilityValue.observer)
    self.vm.outputs.deadlineDateText.observe(self.deadlineDateText.observer)
    self.vm.outputs.launchDateText.observe(self.launchDateText.observer)
    self.vm.outputs.goalText.observe(self.goalText.observer)
    self.vm.outputs.graphData.map { data in data.project }.observe(self.project.observer)
    self.vm.outputs.graphData.map { data in data.stats }.observe(self.stats.observer)
    self.vm.outputs.graphData.map { data in data.yAxisTickSize }.observe(self.yAxisTickSize.observer)
    self.vm.outputs.pledgedText.observe(self.pledgedText.observer)
    self.vm.outputs.timeRemainingSubtitleText.observe(self.timeRemainingSubtitleText.observer)
    self.vm.outputs.timeRemainingTitleText.observe(self.timeRemainingTitleText.observer)
  }

  func testCellAccessibility() {
    let liveProject = .template
      |> Project.lens.stats.backersCount .~ 5
      |> Project.lens.stats.pledged .~ 50
      |> Project.lens.stats.goal .~ 10_000
      |> Project.lens.dates.deadline .~ (Date().timeIntervalSince1970 + 60.0 * 60.0 * 24.0 * 3.0)
      |> Project.lens.country .~ .us

    let stats = [ProjectStatsEnvelope.FundingDateStats.template]
    let deadline = liveProject.dates.deadline!

    self.vm.inputs.configureWith(fundingDateStats: stats, project: liveProject)

    self.cellAccessibilityValue.assertValues(
      [
        Strings.dashboard_graphs_funding_accessibility_live_stat_value(
          pledged: Format.currency(liveProject.stats.pledged, country: liveProject.country),
          goal: Format.currency(liveProject.stats.goal, country: liveProject.country),
          backers_count: liveProject.stats.backersCount,
          time_left: Format.duration(secondsInUTC: deadline).time + " " +
            Format.duration(secondsInUTC: deadline).unit
        )
      ],
      "Live project stats value emits."
    )

    let nonLiveProject = .template |> Project.lens.state .~ .successful
    let nonLiveDeadline = nonLiveProject.dates.deadline!

    self.vm.inputs.configureWith(fundingDateStats: stats, project: nonLiveProject)

    self.cellAccessibilityValue.assertValues(
      [
        Strings.dashboard_graphs_funding_accessibility_live_stat_value(
          pledged: Format.currency(liveProject.stats.pledged, country: liveProject.country),
          goal: Format.currency(liveProject.stats.goal, country: liveProject.country),
          backers_count: liveProject.stats.backersCount,
          time_left: Format.duration(secondsInUTC: deadline).time + " " +
            Format.duration(secondsInUTC: deadline).unit
        ),
        Strings.dashboard_graphs_funding_accessibility_non_live_stat_value(
          pledged: Format.currency(nonLiveProject.stats.pledged, country: nonLiveProject.country),
          goal: Format.currency(nonLiveProject.stats.goal, country: nonLiveProject.country),
          backers_count: nonLiveProject.stats.backersCount,
          time_left: Format.duration(secondsInUTC: nonLiveDeadline).time + " " +
            Format.duration(secondsInUTC: nonLiveDeadline).unit
        )
      ],
      "Non live project stats value emits."
    )
  }

  func testFundingGraphDataEmits() {
    let now = self.dateType.init()

    let stat1 = .template
      |> ProjectStatsEnvelope.FundingDateStats.lens.date .~ (now.timeIntervalSince1970 - 60 * 60 * 24 * 4)
      |> ProjectStatsEnvelope.FundingDateStats.lens.cumulativePledged .~ 500

    let stat2 = .template
      |> ProjectStatsEnvelope.FundingDateStats.lens.date .~ (now.timeIntervalSince1970 - 60 * 60 * 24 * 3)
      |> ProjectStatsEnvelope.FundingDateStats.lens.cumulativePledged .~ 700

    let stat3 = .template
      |> ProjectStatsEnvelope.FundingDateStats.lens.date .~ (now.timeIntervalSince1970 - 60 * 60 * 24 * 2)
      |> ProjectStatsEnvelope.FundingDateStats.lens.cumulativePledged .~ 1_500

    let stat4 = .template
      |> ProjectStatsEnvelope.FundingDateStats.lens.date .~ (now.timeIntervalSince1970 - 60 * 60 * 24 * 1)
      |> ProjectStatsEnvelope.FundingDateStats.lens.cumulativePledged .~ 2_200

    let stat5 = .template
      |> ProjectStatsEnvelope.FundingDateStats.lens.date .~ now.timeIntervalSince1970
      |> ProjectStatsEnvelope.FundingDateStats.lens.cumulativePledged .~ 3_500

    let fundingDateStats = [stat1, stat2, stat3, stat4, stat5]

    let project = .template
      |> Project.lens.dates.deadline .~ now.timeIntervalSince1970
      |> Project.lens.dates.launchedAt .~ (now.timeIntervalSince1970 - 60 * 60 * 24 * 5)
      |> Project.lens.dates.stateChangedAt .~ now.timeIntervalSince1970

    self.vm.inputs.configureWith(fundingDateStats: fundingDateStats, project: project)

    self.project.assertValues([project])
    self.stats.assertValues([[stat1, stat2, stat3, stat4, stat5]])
    self.yAxisTickSize.assertValueCount(1)
  }

  func testProjectDataEmits() {
    let now = self.dateType.init()

    let fundingDateStats = [ProjectStatsEnvelope.FundingDateStats.template]

    let project = .template
      |> Project.lens.stats.backersCount .~ 2_000
      |> Project.lens.dates.deadline .~ (now.timeIntervalSince1970 + 60.0 * 60.0 * 24.0)
      |> Project.lens.stats.goal .~ 50_000
      |> Project.lens.stats.pledged .~ 5_000

    self.vm.inputs.configureWith(fundingDateStats: fundingDateStats, project: project)

    self.backersText.assertValues(["2,000"])
    self.deadlineDateText.assertValueCount(1)
    self.goalText.assertValues(["pledged of $50,000"])
    self.launchDateText.assertValueCount(1)
    self.pledgedText.assertValues(["$5,000"])
    self.timeRemainingSubtitleText.assertValues(["hours to go"])
    self.timeRemainingTitleText.assertValues(["24"])
  }
}
