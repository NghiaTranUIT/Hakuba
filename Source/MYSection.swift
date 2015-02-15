//
//  MYSection.swift
//  MYTableViewManager
//
//  Created by Le VanNghia on 2/14/15.
//  Copyright (c) 2015 Le Van Nghia. All rights reserved.
//

import Foundation

protocol MYSectionDelegate : class {
    func reloadTableView()
    func reloadSections(indexSet: NSIndexSet, animation: MYAnimation)
    func insertRows(indexPaths: [NSIndexPath], animation: MYAnimation)
    func deleteRows(indexPaths: [NSIndexPath], animation: MYAnimation)
    
    func willAddCellViewModels(viewmodels: [MYCellViewModel])
}

private enum ReloadState {
    case Reset, Add, Remove, Begin
}

private class MYSectionReloadTracker {
    private var state: ReloadState = .Begin
    private var addedIndexes: [Int] = []
    private var removedIndexes: [Int] = []
    
    init() {
        didFire()
    }
    
    func didReset() {
        state = .Reset
    }
    
    func didAdd(range: Range<Int>) {
        if state == .Reset || state == .Remove {
            state = .Reset
            return
        }
        for i in range {
            var newIndexes: [Int] = []
            if addedIndexes.indexOf(i) == nil {
                newIndexes.append(i)
            }
            addedIndexes += newIndexes
        }
        state = .Add
    }
    
    func didRemove(range: Range<Int>) {
        if state == .Reset || state == .Add {
            state = .Reset
            return
        }
        for i in range {
            var newIndexes: [Int] = []
            if removedIndexes.indexOf(i) == nil {
                newIndexes.append(i)
            }
            removedIndexes += newIndexes
        }
        state = .Remove
    }
    
    func didFire() {
        state = .Begin
        addedIndexes = []
        removedIndexes = []
    }
    
    func getIndexPaths(section: Int) -> [NSIndexPath] {
        switch state {
        case .Add:
            return addedIndexes.map { NSIndexPath(forRow: $0, inSection: section) }
        case .Remove:
            return removedIndexes.map { NSIndexPath(forRow: $0, inSection: section) }
        default:
            break
        }
        return []
    }
}

public class MYSection {
    internal(set) var index: Int = 0
    weak var delegate: MYSectionDelegate?
    private var items: [MYCellViewModel] = []
    private let reloadTracker = MYSectionReloadTracker()
    
    public var header: MYHeaderFooterViewModel?
    public var footer: MYHeaderFooterViewModel?

    public subscript(index: Int) -> MYCellViewModel? {
        get {
            return items.hasIndex(index) ? items[index] : nil
        }
    }
    
    public init() {
    }
}

public extension MYSection {
    // MARK - reset
    func reset() -> Self {
        items = []
        reloadTracker.didReset()
        return self
    }
    
    func reset(viewmodel: MYCellViewModel) -> Self {
        return reset([viewmodel])
    }
    
    func reset(viewmodels: [MYCellViewModel]) -> Self {
        delegate?.willAddCellViewModels(viewmodels)
        items = viewmodels
        resetIndex(0, end: self.count-1)
        reloadTracker.didReset()
        return self
    }
    
    // MARK - apppend
    func append(viewmodel: MYCellViewModel) -> Self {
        return append([viewmodel])
    }
    
    func append(viewmodels: [MYCellViewModel]) -> Self {
        delegate?.willAddCellViewModels(viewmodels)
        let r = items.append(viewmodels)
        resetIndex(r.startIndex, end: self.count-1)
        reloadTracker.didAdd(r)
        return self
    }
    
    // MARK - insert
    func insert(viewmodel: MYCellViewModel, atIndex index: Int) -> Self {
        return insert([viewmodel], atIndex: index)
    }
    
    func insert(viewmodels: [MYCellViewModel], atIndex index: Int) -> Self {
        delegate?.willAddCellViewModels(viewmodels)
        let r = items.insert(viewmodels, atIndex: index)
        resetIndex(r.startIndex, end: self.count-1)
        reloadTracker.didAdd(r)
        return self
    }
    
    // MARK - remove
    func remove(index: Int) -> Self {
        if let r = items.remove(index) {
            resetIndex(r.startIndex, end: self.count-1)
            reloadTracker.didRemove(r)
        }
        return self
    }
    
    func removeLast() -> Self {
        self.remove(items.count - 1)
        return self
    }
    
    func remove(range: Range<Int>) -> Self {
        if let r = items.remove(range) {
            resetIndex(r.startIndex, end: self.count-1)
            reloadTracker.didRemove(r)
        }
        return self
    }
    
    // MARK - fire
    func fire(_ animation: MYAnimation = .None) -> Self {
        switch reloadTracker.state {
        case .Add:
            println("ADD")
            delegate?.insertRows(reloadTracker.getIndexPaths(index), animation: animation)
        case .Remove:
            println("REMOVE")
            delegate?.deleteRows(reloadTracker.getIndexPaths(index), animation: animation)
        default:
            println("RESET")
            delegate?.reloadSections(NSIndexSet(index: index), animation: animation)
            break
        }
        reloadTracker.didFire()
        return self
    }
    
    private func resetIndex(begin: Int, end: Int) {
        if begin > end {
            return
        }
        for i in (begin...end) {
            items[i].row = i
            items[i].section = index
        }
    }
}

public extension MYSection {
    var count: Int {
        return items.count
    }
    
    var isEmpty: Bool {
        return items.count == 0
    }

    var first: MYCellViewModel? {
        return items.first
    }
    
    var last: MYCellViewModel? {
        return items.last
    }
}