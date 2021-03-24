import Foundation
import Combine
import SwiftUI

struct SegmentedPickerElementView<T>: Hashable, View where T: Buttonable {

	let id: T
	let row: Int
	let col: Int
	let content: String
	let longContent: String
	@Binding var longPressState: [[Bool]]

	static func == (lhs: SegmentedPickerElementView<T>, rhs: SegmentedPickerElementView<T>) -> Bool {
		return lhs.id == rhs.id
	}
	
	func hash(into hasher: inout Hasher) {
		hasher.combine(id)
	}
	
	var body: some View {
		VStack {
			if self.longPressState[self.row][self.col] {
				GeometryReader { proxy in
					Text(self.longContent)
						.font(.body)
				}
			} else {
				GeometryReader { proxy in
					Text(self.content)
						.font(.body)
				}
			}
		}
	}
}

struct MultiRowSegmentedPickerView<T: Buttonable>: View {
	var elementWidth: CGFloat = 0
	@Binding private var selectedIndex: T

	@State private var width: CGFloat = 380
	@State private var height: CGFloat = 84
	
	private let cornerRadius: CGFloat = 8
	private let selectorStrokeWidth: CGFloat = 4
	private let selectorInset: CGFloat = 5
	private let backgroundColor = Color("ActionButtonBackground")

	private let choices: [[T]]
	@State private var longPressState: [[Bool]]
	
	private let onChange: (_ newValue: T) -> Void
	
	init(
		choices: [[T]],
		selectedIndex: Binding<T>,
		onChange: @escaping (_ newValue: T) -> Void = { _ in }
	) {
		debugLog("MultiRowSegmentedPickerView.init")
		
		self.choices = choices
		self.onChange = onChange
		_selectedIndex = selectedIndex

		var newLongPressState: [[Bool]] = []
		for r in choices.indices {
			var rowLongPress: [Bool] = []
			let rowChoices = choices[r]
			for _ in rowChoices.indices {
				rowLongPress.append(false)
			}
			newLongPressState.append(rowLongPress)
		}
		_longPressState = State(initialValue: newLongPressState)
		
		updateSelectionOffset(item: selectedIndex.wrappedValue, force: true)
	}
	
	@State var selectionIndex: CGFloat = 0
	@State var selectionOffsetX: CGFloat = 0
	@State var selectionOffsetY: CGFloat = 0
	@State var selectionWidth: CGFloat = 0
	@State var selectionHeight: CGFloat = 0
	func updateSelectionOffset(item: T, force: Bool = false, longPress: Bool = false) {
		
		debugLog("MultiRowSegmentedPickerView.updateSelectionOffset(\(item))")
		
		var row = 0
		var col = 0
		for r in 0 ..< choices.count {
			let choiceRow = choices[r]
			for c in 0 ..< choiceRow.count {
				longPressState[r][c] = false
				if choices[r][c] == item {
					row = r
					col = c
				}
			}
		}
		
		var newItem = item
		if longPress && item.longPressVersion != nil {
			newItem = item.longPressVersion!
			longPressState[row][col] = true
		} else {
			newItem = item
			longPressState[row][col] = false
		}
		
		if newItem != selectedIndex || force {
			selectedIndex = newItem
			selectionWidth = self.width/CGFloat(self.choices[row].count)
			selectionHeight = self.height/CGFloat(self.choices.count)
			selectionOffsetX = CGFloat((selectionWidth * CGFloat(col)) + selectionWidth/2.0)
			selectionOffsetY = CGFloat((selectionHeight * CGFloat(row)) + selectionHeight/2.0)
			onChange(newItem)
		}
		
	}
	
	var body: some View {
		GeometryReader { geo in
			VStack {
				ZStack(alignment: .leading) {
					self.elementsView
					RoundedRectangle(cornerRadius: self.cornerRadius)
						.stroke(Color.primary, lineWidth: self.selectorStrokeWidth)
						.foregroundColor(Color.clear)
						.frame(
							width: self.selectionWidth - 2.0 * self.selectorInset,
							height: self.selectionHeight - 2.0 * self.selectorInset
					)
						.position(x: self.selectionOffsetX, y: self.selectionOffsetY)
//						.animation(.easeInOut(duration: 0.2))
				}
				.background(self.backgroundColor)
				.cornerRadius(self.cornerRadius)
			}
			.onAppear(
				perform: {
					self.width = geo.size.width
					self.height = geo.size.height
					self.updateSelectionOffset(item: self.choices[0][0], force: true)
			}
			)
		}
		.frame(maxWidth: .infinity, maxHeight: CGFloat(60 * self.choices.count), alignment: .top)
	}
	
	var elementsView: some View {
		VStack {
			ForEach(self.choices.indices) { row in
				HStack(alignment: .center, spacing: 0) {
					ForEach(self.choices[row].indices) { col in
						self.elementView(item: self.choices[row][col], row: row, col: col)
					}
				}
			}
		}
	}
	
	func elementView(item: T, row: Int, col: Int) -> some View {
		VStack {
			GeometryReader { proxy in
				Text(
					self.getButtonString(
						item: item,
						longPressState: self.longPressState[row][col]
					)
				)
				.frame(width: self.selectionWidth, height: self.selectionHeight, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
					.font(.body)
					.contentShape(Rectangle())
					.onTapGesture(
						count: 2,
						perform: {
							debugLog("MultiRowSegmentPickerView: double tap \(item.asString)")
							withAnimation(.none) {
								self.updateSelectionOffset(item: item, longPress: true)
							}
					}
				)
					.onTapGesture(
						count: 1,
						perform: {
							debugLog("MultiRowSegmentPickerView: single tap \(item.asString)")
							withAnimation(.none) {
								self.updateSelectionOffset(item: item, longPress: false)
							}
					}
				)
//					.onLongPressGesture(
//						minimumDuration: Double(longPressDuration),
//						maximumDistance: longPressMaxDrift,
//						pressing: { down in
//							debugLog("MultiRowSegmentPickerView: long press \(item.asString)")
//							withAnimation(.none) {
//								if down {
//									self.actionDetail = item.longDescription
//								}
//							}
//					}, perform: {
//						withAnimation {
//							self.updateSelectionOffset(item: item, row: row, col: col, longPress: true)
//						}
//					}
//				)
			}
		}
	}
	
	func getButtonString(item: T, longPressState: Bool) -> String {
		if longPressState {
			return item.longPressVersion?.asString ?? ""
		} else {
			return item.asString
		}
	}
	
}

struct SegmentedPickerView_Previews: PreviewProvider {
	
	@State static var selectedAction: FundAction = .spend
	@State static var actionDetail = "None"
	
	static var previews: some View {
		Group {
			MultiRowSegmentedPickerView(
				choices: FundAction.allCasesInRows,
				selectedIndex: $selectedAction
			)
				.environment(\.colorScheme, .light)
			
			MultiRowSegmentedPickerView(
				choices: FundAction.allCasesInRows,
				selectedIndex: $selectedAction
			)
				.environment(\.colorScheme, .dark)
		}
	}
	
}
