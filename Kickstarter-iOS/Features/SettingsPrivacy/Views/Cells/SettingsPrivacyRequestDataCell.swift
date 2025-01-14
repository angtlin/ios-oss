import KsApi
import Library
import Prelude
import Prelude_UIKit
import ReactiveSwift
import UIKit

internal protocol SettingsRequestDataCellDelegate: AnyObject {
  func settingsRequestDataCellDidPresentPrompt(_ cell: SettingsPrivacyRequestDataCell, alertMessage: String)
  func settingsRequestDataCell(_ cell: SettingsPrivacyRequestDataCell, requestedDataWith url: String)
}

internal final class SettingsPrivacyRequestDataCell: UITableViewCell, ValueCell {
  fileprivate let viewModel: SettingsRequestDataCellViewModelType = SettingsRequestDataCellViewModel()
  internal weak var delegate: SettingsRequestDataCellDelegate?

  @IBOutlet fileprivate var containerView: UIView!
  @IBOutlet fileprivate var chevron: UIImageView!
  @IBOutlet fileprivate var preparingDataLabel: UILabel!
  @IBOutlet fileprivate var checkBackLaterLabel: UILabel!
  @IBOutlet fileprivate var requestDataActivityIndicator: UIActivityIndicatorView!
  @IBOutlet fileprivate var requestDataButton: UIButton!
  @IBOutlet fileprivate var requestDataLabel: UILabel!
  @IBOutlet fileprivate var requestedDataStatusAndDateLabel: UILabel!
  @IBOutlet fileprivate var separatorViews: [UIView]!

  private var requestDataObserver: Any?

  internal override func awakeFromNib() {
    super.awakeFromNib()

    self.requestDataButton.addTarget(self, action: #selector(self.exportButtonTapped), for: .touchUpInside)

    self.requestDataObserver = NotificationCenter.default.addObserver(
      forName: Notification.Name.ksr_dataRequested,
      object: nil, queue: nil
    ) { [weak self] _ in self?.viewModel.inputs.startRequestDataTapped() }

    self.viewModel.inputs.awakeFromNib()
  }

  deinit {
    self.requestDataObserver.doIfSome(NotificationCenter.default.removeObserver)
  }

  internal func configureWith(value: User) {
    self.viewModel.inputs.configureWith(user: value)
  }

  internal override func bindStyles() {
    super.bindStyles()

    _ = self
      |> baseTableViewCellStyle()
      |> UITableViewCell.lens.contentView.layoutMargins %~~ { _, cell in
        cell.traitCollection.isRegularRegular
          ? .init(topBottom: Styles.grid(2), leftRight: Styles.grid(20))
          : .init(topBottom: Styles.grid(1), leftRight: Styles.grid(2))
      }

    _ = self.contentView
      |> \.backgroundColor .~ .ksr_support_100

    _ = self.separatorViews
      ||> settingsSeparatorStyle

    _ = self.requestDataButton
      |> UIButton.lens.backgroundColor(for: .highlighted) .~ .ksr_support_400

    _ = self.chevron
      |> UIImageView.lens.tintColor .~ .ksr_support_400
      |> UIImageView.lens.contentMode .~ .scaleAspectFit

    _ = self.preparingDataLabel
      |> settingsTitleLabelStyle
      |> UILabel.lens.numberOfLines .~ 1
      |> UILabel.lens.text %~ { _ in Strings.Preparing_your_personal_data() }

    _ = self.checkBackLaterLabel
      |> UILabel.lens.textColor .~ .ksr_support_400
      |> UILabel.lens.font .~ .ksr_body(size: 13)
      |> UILabel.lens.text %~ { _ in Strings.Check_back_later_for_an_update_on_your_export() }

    _ = self.requestDataActivityIndicator
      |> UIActivityIndicatorView.lens.hidesWhenStopped .~ true

    _ = self.requestDataLabel
      |> settingsTitleLabelStyle
      |> UILabel.lens.numberOfLines .~ 1

    _ = self.requestedDataStatusAndDateLabel
      |> UILabel.lens.textColor .~ .ksr_support_400
      |> UILabel.lens.font .~ .ksr_body(size: 13)
  }

  internal override func bindViewModel() {
    super.bindViewModel()

    self.viewModel.outputs.showRequestDataPrompt
      .observeForUI()
      .observeValues { [weak self] requestDataAlertText in
        guard let _self = self else { return }
        self?.delegate?.settingsRequestDataCellDidPresentPrompt(_self, alertMessage: requestDataAlertText)
      }

    self.viewModel.outputs.goToSafari
      .observeForUI()
      .observeValues { [weak self] url in
        guard let _self = self else { return }
        self?.delegate?.settingsRequestDataCell(_self, requestedDataWith: url)
      }

    self.requestDataButton.rac.enabled = self.viewModel.outputs.requestDataButtonEnabled
    self.requestDataActivityIndicator.rac.animating = self.viewModel.outputs.requestDataLoadingIndicator
    self.requestDataLabel.rac.text = self.viewModel.outputs.requestDataText
    self.requestedDataStatusAndDateLabel.rac.text = self.viewModel.outputs.requestedDataExpirationDate
    self.chevron.rac.hidden = self.viewModel.outputs.dataExpirationAndChevronHidden
    self.requestDataLabel.rac.hidden = self.viewModel.outputs.requestDataTextHidden
    self.preparingDataLabel.rac.hidden = self.viewModel.outputs.preparingDataAndCheckBackLaterTextHidden
    self.checkBackLaterLabel.rac.hidden = self.viewModel.outputs.preparingDataAndCheckBackLaterTextHidden
    self.requestedDataStatusAndDateLabel.rac.hidden = self.viewModel.outputs.dataExpirationAndChevronHidden
  }

  @objc fileprivate func exportButtonTapped() {
    self.viewModel.inputs.exportDataTapped()
  }
}
