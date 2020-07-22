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

//	@inlinable init(id: T, row: Int, col: Int, content: String, longContent: String, longPressState: ) {
//		self.id = id
//		self.row = row
//		self.col = col
//		self.content = content
//		self.longContent = longContent
//	}
//
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
	@Environment (\.colorScheme) var colorScheme: ColorScheme
	@State var elementWidth: CGFloat = 0
	@Binding private var selectedIndex: T
	@EnvironmentObject var budgetStack: BudgetStack

	@State private var width: CGFloat = 380
	@State private var height: CGFloat = 84
	
	private let cornerRadius: CGFloat = 8
	private let selectorStrokeWidth: CGFloat = 4
	private let selectorInset: CGFloat = 5
	private let backgroundColor = Color("ActionButtonBackground")
	
	private var elements: [[SegmentedPickerElementView<T>]] = []
	@State private var longPressState: [[Bool]]
	
	private let onChange: (_ newValue: T) -> Void
	
	init(
		choices: [[T]],
		selectedIndex: Binding<T>,
		onChange: @escaping (_ newValue: T) -> Void = { _ in }
	) {
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

		var newElements: [[SegmentedPickerElementView<T>]] = []
		for r in choices.indices {
			let rowChoices = choices[r]
			var rowElements = [SegmentedPickerElementView<T>]()
			var rowLongPress: [Bool] = []
			for c in rowChoices.indices {
				let choice = rowChoices[c]
				rowElements.append(
					SegmentedPickerElementView(
						id: choice,
						row: r,
						col: c,
						content: choice.asString,
						longContent: choice.longPressVersion?.asString ?? "",
						longPressState: self.$longPressState
					)
				)
				rowLongPress.append(false)
			}
			newElements.append(rowElements)
		}
		self.elements = newElements
	}
	
	@State var selectionIndex: CGFloat = 0
	@State var selectionOffsetX: CGFloat = 0
	@State var selectionOffsetY: CGFloat = 0
	@State var selectionWidth: CGFloat = 0
	@State var selectionHeight: CGFloat = 0
	func updateSelectionOffset(element: SegmentedPickerElementView<T>, force: Bool = false, longPress: Bool) {
		let id: T
		let row = element.row
		let col = element.col
		if longPress && element.id.longPressVersion != nil {
			id = element.id.longPressVersion!
			longPressState[row][col] = true
		} else {
			id = element.id
			longPressState[row][col] = false
		}
		
		withAnimation(.none) {
			budgetStack.titleOverride = id.description
		}

		if id != selectedIndex || force {
			selectedIndex = id
			selectionWidth = self.width/CGFloat(self.elements[row].count)
			selectionHeight = self.height/CGFloat(self.elements.count)
			selectionOffsetX = CGFloat((selectionWidth * CGFloat(col)) + selectionWidth/2.0)
			selectionOffsetY = CGFloat((selectionHeight * CGFloat(row)) + selectionHeight/2.0)
			onChange(id)
		}
	}
	
	var body: some View {
		GeometryReader { geo in
			VStack {
				ZStack(alignment: .leading) {
					VStack {
						ForEach(self.elements, id: \.self) { row in
							HStack(alignment: .center, spacing: 0) {
								ForEach(row, id: \.self) { item in
									(item as SegmentedPickerElementView)
										.contentShape(Rectangle())
										.onTapGesture(
											perform: {
												withAnimation {
													self.updateSelectionOffset(element: item, longPress: false)
												}
										}
									)
									.onLongPressGesture(
										minimumDuration: longPressDuration,
										maximumDistance: longPressMaxDrift,
										pressing: { down in
											withAnimation(.none) {
												if down {
													self.budgetStack.titleOverride = item.id.description
												}
											}
									}, perform: {
											withAnimation {
												self.updateSelectionOffset(element: item, longPress: true)
											}
									}
									)
								}
							}
						}
					}
					RoundedRectangle(cornerRadius: self.cornerRadius)
						.stroke(Color.primary, lineWidth: self.selectorStrokeWidth)
						.foregroundColor(Color.clear)
						.frame(
							width: self.selectionWidth - 2.0 * self.selectorInset,
							height: self.selectionHeight - 2.0 * self.selectorInset
					)
						.position(x: self.selectionOffsetX, y: self.selectionOffsetY)
						.animation(.easeInOut(duration: 0.2))
				}
				.background(self.backgroundColor)
				.cornerRadius(self.cornerRadius)
			}
			.onAppear(
				perform: {
					self.width = geo.size.width
					self.height = geo.size.height
					self.updateSelectionOffset(element: self.elements[0][0], force: true, longPress: false)
			}
			)
		}
		.frame(maxWidth: .infinity, maxHeight: CGFloat(60 * self.elements.count), alignment: .top)
	}
}

struct SegmentedPickerView_Previews: PreviewProvider {
	@State static var selectedAction: FundAction = .spend
	static var previews: some View {
		Group {
			MultiRowSegmentedPickerView(choices: FundAction.allCasesInRows, selectedIndex: $selectedAction)
				.environment(\.colorScheme, .light)
			
			MultiRowSegmentedPickerView(choices: FundAction.allCasesInRows, selectedIndex: $selectedAction)
				.environment(\.colorScheme, .dark)
		}
	}
}
