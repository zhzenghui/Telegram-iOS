import Foundation
import UIKit
import Display
import SwiftSignalKit
import Postbox
import TelegramCore
import SyncCore
import MapKit
import TelegramPresentationData
import TelegramUIPreferences
import TelegramStringFormatting
import ItemListUI
import PresentationDataUtils
import AccountContext
import PresentationDataUtils
import AppBundle
import Charts

private final class StatsControllerArguments {
    let loadDetailedGraph: (ChannelStatsGraph, Int64) -> Signal<ChannelStatsGraph?, NoError>
    
    init(loadDetailedGraph: @escaping (ChannelStatsGraph, Int64) -> Signal<ChannelStatsGraph?, NoError>) {
        self.loadDetailedGraph = loadDetailedGraph
    }
}

private enum StatsSection: Int32 {
    case overview
    case growth
    case followers
    case notifications
    case viewsByHour
    case postInteractions
    case viewsBySource
    case followersBySource
    case languages
}

private enum StatsEntry: ItemListNodeEntry {
    case overviewHeader(PresentationTheme, String, String)
    case overview(PresentationTheme, ChannelStats)
    
    case growthTitle(PresentationTheme, String)
    case growthGraph(PresentationTheme, PresentationStrings, PresentationDateTimeFormat, ChannelStatsGraph, ChartType)
    
    case followersTitle(PresentationTheme, String)
    case followersGraph(PresentationTheme, PresentationStrings, PresentationDateTimeFormat, ChannelStatsGraph, ChartType)
     
    case notificationsTitle(PresentationTheme, String)
    case notificationsGraph(PresentationTheme, PresentationStrings, PresentationDateTimeFormat, ChannelStatsGraph, ChartType)
    
    case viewsByHourTitle(PresentationTheme, String)
    case viewsByHourGraph(PresentationTheme, PresentationStrings, PresentationDateTimeFormat, ChannelStatsGraph, ChartType)
    
    case postInteractionsTitle(PresentationTheme, String)
    case postInteractionsGraph(PresentationTheme, PresentationStrings, PresentationDateTimeFormat, ChannelStatsGraph, ChartType)
    
    case viewsBySourceTitle(PresentationTheme, String)
    case viewsBySourceGraph(PresentationTheme, PresentationStrings, PresentationDateTimeFormat, ChannelStatsGraph, ChartType)
    
    case followersBySourceTitle(PresentationTheme, String)
    case followersBySourceGraph(PresentationTheme, PresentationStrings, PresentationDateTimeFormat, ChannelStatsGraph, ChartType)
    
    case languagesTitle(PresentationTheme, String)
    case languagesGraph(PresentationTheme, PresentationStrings, PresentationDateTimeFormat, ChannelStatsGraph, ChartType)
    
    var section: ItemListSectionId {
        switch self {
            case .overviewHeader, .overview:
                return StatsSection.overview.rawValue
            case .growthTitle, .growthGraph:
                return StatsSection.growth.rawValue
            case .followersTitle, .followersGraph:
                return StatsSection.followers.rawValue
            case .notificationsTitle, .notificationsGraph:
                return StatsSection.notifications.rawValue
            case .viewsByHourTitle, .viewsByHourGraph:
                return StatsSection.viewsByHour.rawValue
            case .postInteractionsTitle, .postInteractionsGraph:
                return StatsSection.postInteractions.rawValue
            case .viewsBySourceTitle, .viewsBySourceGraph:
                return StatsSection.viewsBySource.rawValue
            case .followersBySourceTitle, .followersBySourceGraph:
                return StatsSection.followersBySource.rawValue
            case .languagesTitle, .languagesGraph:
                return StatsSection.languages.rawValue
        }
    }
    
    var stableId: Int32 {
        switch self {
            case .overviewHeader:
                return 0
            case .overview:
                return 1
            case .growthTitle:
                return 2
            case .growthGraph:
                return 3
            case .followersTitle:
                return 4
            case .followersGraph:
                return 5
            case .notificationsTitle:
                return 6
            case .notificationsGraph:
                return 7
            case .viewsByHourTitle:
                return 8
            case .viewsByHourGraph:
                return 9
            case .postInteractionsTitle:
                return 10
            case .postInteractionsGraph:
                return 11
            case .viewsBySourceTitle:
                return 12
            case .viewsBySourceGraph:
                return 13
            case .followersBySourceTitle:
                return 14
            case .followersBySourceGraph:
                return 15
            case .languagesTitle:
                return 16
            case .languagesGraph:
                return 17
        }
    }
    
    static func ==(lhs: StatsEntry, rhs: StatsEntry) -> Bool {
        switch lhs {
            case let .overviewHeader(lhsTheme, lhsText, lhsDates):
                if case let .overviewHeader(rhsTheme, rhsText, rhsDates) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsDates == rhsDates {
                    return true
                } else {
                    return false
                }
            case let .overview(lhsTheme, lhsStats):
                if case let .overview(rhsTheme, rhsStats) = rhs, lhsTheme === rhsTheme, lhsStats == rhsStats {
                    return true
                } else {
                    return false
                }
            case let .growthTitle(lhsTheme, lhsText):
                if case let .growthTitle(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
            case let .growthGraph(lhsTheme, lhsStrings, lhsDateTimeFormat, lhsGraph, lhsType):
                if case let .growthGraph(rhsTheme, rhsStrings, rhsDateTimeFormat, rhsGraph, rhsType) = rhs, lhsTheme === rhsTheme, lhsStrings === rhsStrings, lhsDateTimeFormat == rhsDateTimeFormat, lhsGraph == rhsGraph, lhsType == rhsType {
                    return true
                } else {
                    return false
                }
            case let .followersTitle(lhsTheme, lhsText):
                if case let .followersTitle(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
            case let .followersGraph(lhsTheme, lhsStrings, lhsDateTimeFormat, lhsGraph, lhsType):
                if case let .followersGraph(rhsTheme, rhsStrings, rhsDateTimeFormat, rhsGraph, rhsType) = rhs, lhsTheme === rhsTheme, lhsStrings === rhsStrings, lhsDateTimeFormat == rhsDateTimeFormat, lhsGraph == rhsGraph, lhsType == rhsType {
                    return true
                } else {
                    return false
                }
            case let .notificationsTitle(lhsTheme, lhsText):
                  if case let .notificationsTitle(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                      return true
                  } else {
                      return false
                  }
            case let .notificationsGraph(lhsTheme, lhsStrings, lhsDateTimeFormat, lhsGraph, lhsType):
                if case let .notificationsGraph(rhsTheme, rhsStrings, rhsDateTimeFormat, rhsGraph, rhsType) = rhs, lhsTheme === rhsTheme, lhsStrings === rhsStrings, lhsDateTimeFormat == rhsDateTimeFormat, lhsGraph == rhsGraph, lhsType == rhsType {
                    return true
                } else {
                    return false
                }
            case let .viewsByHourTitle(lhsTheme, lhsText):
                if case let .viewsByHourTitle(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
            case let .viewsByHourGraph(lhsTheme, lhsStrings, lhsDateTimeFormat, lhsGraph, lhsType):
                if case let .viewsByHourGraph(rhsTheme, rhsStrings, rhsDateTimeFormat, rhsGraph, rhsType) = rhs, lhsTheme === rhsTheme, lhsStrings === rhsStrings, lhsDateTimeFormat == rhsDateTimeFormat, lhsGraph == rhsGraph, lhsType == rhsType {
                    return true
                } else {
                    return false
                }
            case let .postInteractionsTitle(lhsTheme, lhsText):
                if case let .postInteractionsTitle(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                    return true
                } else {
                    return false
            }
            case let .postInteractionsGraph(lhsTheme, lhsStrings, lhsDateTimeFormat, lhsGraph, lhsType):
                if case let .postInteractionsGraph(rhsTheme, rhsStrings, rhsDateTimeFormat, rhsGraph, rhsType) = rhs, lhsTheme === rhsTheme, lhsStrings === rhsStrings, lhsDateTimeFormat == rhsDateTimeFormat, lhsGraph == rhsGraph, lhsType == rhsType {
                    return true
                } else {
                    return false
                }
            case let .viewsBySourceTitle(lhsTheme, lhsText):
                if case let .viewsBySourceTitle(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
            case let .viewsBySourceGraph(lhsTheme, lhsStrings, lhsDateTimeFormat, lhsGraph, lhsType):
                if case let .viewsBySourceGraph(rhsTheme, rhsStrings, rhsDateTimeFormat, rhsGraph, rhsType) = rhs, lhsTheme === rhsTheme, lhsStrings === rhsStrings, lhsDateTimeFormat == rhsDateTimeFormat, lhsGraph == rhsGraph, lhsType == rhsType {
                    return true
                } else {
                    return false
                }
            case let .followersBySourceTitle(lhsTheme, lhsText):
                if case let .followersBySourceTitle(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
            case let .followersBySourceGraph(lhsTheme, lhsStrings, lhsDateTimeFormat, lhsGraph, lhsType):
                if case let .followersBySourceGraph(rhsTheme, rhsStrings, rhsDateTimeFormat, rhsGraph, rhsType) = rhs, lhsTheme === rhsTheme, lhsStrings === rhsStrings, lhsDateTimeFormat == rhsDateTimeFormat, lhsGraph == rhsGraph, lhsType == rhsType {
                    return true
                } else {
                    return false
                }
            case let .languagesTitle(lhsTheme, lhsText):
                if case let .languagesTitle(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
            case let .languagesGraph(lhsTheme, lhsStrings, lhsDateTimeFormat, lhsGraph, lhsType):
                if case let .languagesGraph(rhsTheme, rhsStrings, rhsDateTimeFormat, rhsGraph, rhsType) = rhs, lhsTheme === rhsTheme, lhsStrings === rhsStrings, lhsDateTimeFormat == rhsDateTimeFormat, lhsGraph == rhsGraph, lhsType == rhsType {
                    return true
                } else {
                    return false
                }
        }
    }
    
    static func <(lhs: StatsEntry, rhs: StatsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }
    
    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! StatsControllerArguments
        switch self {
            case let .overviewHeader(theme, text, dates):
                return ItemListSectionHeaderItem(presentationData: presentationData, text: text, accessoryText: ItemListSectionHeaderAccessoryText(value: dates, color: .generic), sectionId: self.section)
            case let .growthTitle(theme, text),
                 let .followersTitle(theme, text),
                 let .notificationsTitle(theme, text),
                 let .viewsByHourTitle(theme, text),
                 let .postInteractionsTitle(theme, text),
                 let .viewsBySourceTitle(theme, text),
                 let .followersBySourceTitle(theme, text),
                 let .languagesTitle(theme, text):
                return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
            case let .overview(theme, stats):
                return StatsOverviewItem(presentationData: presentationData, stats: stats, sectionId: self.section, style: .blocks)
            case let .growthGraph(theme, strings, dateTimeFormat, graph, type):
                return StatsGraphItem(presentationData: presentationData, graph: graph, type: type, sectionId: self.section, style: .blocks)
            case let .followersGraph(theme, strings, dateTimeFormat, graph, type):
                return StatsGraphItem(presentationData: presentationData, graph: graph, type: type, sectionId: self.section, style: .blocks)
            case let .notificationsGraph(theme, strings, dateTimeFormat, graph, type):
                return StatsGraphItem(presentationData: presentationData, graph: graph, type: type, sectionId: self.section, style: .blocks)
            case let .viewsByHourGraph(theme, strings, dateTimeFormat, graph, type):
                return StatsGraphItem(presentationData: presentationData, graph: graph, type: type, sectionId: self.section, style: .blocks)
            case let .postInteractionsGraph(theme, strings, dateTimeFormat, graph, type):
                return StatsGraphItem(presentationData: presentationData, graph: graph, type: type, getDetailsData: { date, completion in
                    let _ = arguments.loadDetailedGraph(graph, Int64(date.timeIntervalSince1970))
                }, sectionId: self.section, style: .blocks)
            case let .viewsBySourceGraph(theme, strings, dateTimeFormat, graph, type):
                return StatsGraphItem(presentationData: presentationData, graph: graph, type: type, height: 160.0, sectionId: self.section, style: .blocks)
            case let .followersBySourceGraph(theme, strings, dateTimeFormat, graph, type):
                return StatsGraphItem(presentationData: presentationData, graph: graph, type: type, height: 160.0, sectionId: self.section, style: .blocks)
            case let .languagesGraph(theme, strings, dateTimeFormat, graph, type):
                return StatsGraphItem(presentationData: presentationData, graph: graph, type: type, height: 100.0, sectionId: self.section, style: .blocks)
        }
    }
}

private func statsControllerEntries(data: ChannelStats?, presentationData: PresentationData) -> [StatsEntry] {
    var entries: [StatsEntry] = []
    
    if let data = data {
        let minDate = stringForDate(timestamp: data.period.minDate, strings: presentationData.strings)
        let maxDate = stringForDate(timestamp: data.period.maxDate, strings: presentationData.strings)
        
        entries.append(.overviewHeader(presentationData.theme, presentationData.strings.Stats_Overview, "\(minDate) – \(maxDate)"))
        entries.append(.overview(presentationData.theme, data))
    
        entries.append(.growthTitle(presentationData.theme, presentationData.strings.Stats_GrowthTitle))
        entries.append(.growthGraph(presentationData.theme, presentationData.strings, presentationData.dateTimeFormat, data.growthGraph, .lines))
        
        entries.append(.followersTitle(presentationData.theme, presentationData.strings.Stats_FollowersTitle))
        entries.append(.followersGraph(presentationData.theme, presentationData.strings, presentationData.dateTimeFormat, data.followersGraph, .lines))
        
        entries.append(.notificationsTitle(presentationData.theme, presentationData.strings.Stats_NotificationsTitle))
        entries.append(.notificationsGraph(presentationData.theme, presentationData.strings, presentationData.dateTimeFormat, data.muteGraph, .lines))
        
        entries.append(.postInteractionsTitle(presentationData.theme, presentationData.strings.Stats_InteractionsTitle))
        entries.append(.postInteractionsGraph(presentationData.theme, presentationData.strings, presentationData.dateTimeFormat, data.interactionsGraph, .twoAxis))
        
        entries.append(.viewsBySourceTitle(presentationData.theme, presentationData.strings.Stats_ViewsBySourceTitle))
        entries.append(.viewsBySourceGraph(presentationData.theme, presentationData.strings, presentationData.dateTimeFormat, data.viewsBySourceGraph, .bars))
        
        entries.append(.followersBySourceTitle(presentationData.theme, presentationData.strings.Stats_FollowersBySourceTitle))
        entries.append(.followersBySourceGraph(presentationData.theme, presentationData.strings, presentationData.dateTimeFormat, data.newFollowersBySourceGraph, .bars))
        
        entries.append(.languagesTitle(presentationData.theme, presentationData.strings.Stats_LanguagesTitle))
        entries.append(.languagesGraph(presentationData.theme, presentationData.strings, presentationData.dateTimeFormat, data.languagesGraph, .pie))
    }
    
    return entries
}

public func channelStatsController(context: AccountContext, peer: Peer, cachedPeerData: CachedPeerData) -> ViewController {
    var pushControllerImpl: ((ViewController) -> Void)?
    var presentControllerImpl: ((ViewController, ViewControllerPresentationArguments?) -> Void)?
    var navigateToChatImpl: ((Peer) -> Void)?
    
    let actionsDisposable = DisposableSet()
    let checkCreationAvailabilityDisposable = MetaDisposable()
    actionsDisposable.add(checkCreationAvailabilityDisposable)
    
    let dataPromise = Promise<ChannelStats?>(nil)
    
    var datacenterId: Int32 = 0
    if let cachedData = cachedPeerData as? CachedChannelData {
        datacenterId = cachedData.statsDatacenterId
    }
        
    let statsContext = ChannelStatsContext(postbox: context.account.postbox, network: context.account.network, datacenterId: datacenterId, peerId: peer.id)
    let dataSignal: Signal<ChannelStats?, NoError> = statsContext.state
    |> map { state in
        return state.stats
    } |> afterNext({ [weak statsContext] a in
        if let w = statsContext, let a = a {
            if case .OnDemand = a.interactionsGraph {
                w.loadInteractionsGraph()
                w.loadNewFollowersBySourceGraph()
                w.loadViewsBySourceGraph()
                w.loadLanguagesGraph()
            }
        }
    })
    dataPromise.set(.single(nil) |> then(dataSignal))
    
    let arguments = StatsControllerArguments(loadDetailedGraph: { graph, x -> Signal<ChannelStatsGraph?, NoError> in
        return statsContext.loadDetailedGraph(graph, x: x)
    })
    
    let signal = combineLatest(context.sharedContext.presentationData, dataPromise.get())
    |> deliverOnMainQueue
    |> map { presentationData, data -> (ItemListControllerState, (ItemListNodeState, Any)) in
        var emptyStateItem: ItemListControllerEmptyStateItem?
        if data == nil {
            emptyStateItem = ItemListLoadingIndicatorEmptyStateItem(theme: presentationData.theme)
        }
        
        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text(presentationData.strings.ChannelInfo_Stats), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back), animateChanges: true)
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: statsControllerEntries(data: data, presentationData: presentationData), style: .blocks, emptyStateItem: emptyStateItem, crossfadeState: false, animateChanges: false)
        
        return (controllerState, (listState, arguments))
    }
    |> afterDisposed {
        actionsDisposable.dispose()
        let _ = statsContext.state
    }
    
    let controller = ItemListController(context: context, state: signal)
    controller.didDisappear = { [weak controller] _ in
        controller?.clearItemNodesHighlight(animated: true)
    }
    pushControllerImpl = { [weak controller] c in
        if let controller = controller {
            (controller.navigationController as? NavigationController)?.pushViewController(c, animated: true)
        }
    }
    presentControllerImpl = { [weak controller] c, a in
        if let controller = controller {
            controller.present(c, in: .window(.root), with: a)
        }
    }
    
    return controller
}