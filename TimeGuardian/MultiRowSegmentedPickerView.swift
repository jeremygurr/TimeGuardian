import Foundation
import Combine
import SwiftUI

struct SegmentedPickerElementView<Content, T>: Hashable, View where Content: View, T: Stringable {

	let id: T
	let row: Int
	let col: Int
	let content: () -> Content
	
	@inlinable init(id: T, row: Int, col: Int, @ViewBuilder content: @escaping () -> Content) {
		self.id = id
		self.row = row
		self.col = col
		self.content = content
	}
	
	static func == (lhs: SegmentedPickerElementView<Content, T>, rhs: SegmentedPickerElementView<Content, T>) -> Bool {
		return lhs.id == rhs.id
	}
	
	func hash(into hasher: inout Hasher) {
		hasher.combine(id)
	}
	
	var body: some View {
		GeometryReader { proxy in
			self.content()
		}
	}
}

struct MultiRowSegmentedPickerView<T: Stringable>: View {
	@Environment (\.colorScheme) var colorScheme: ColorScheme
	@State var elementWidth: CGFloat = 0
	@Binding private var selectedIndex: T

	@State private var width: CGFloat = 380
	@State private var height: CGFloat = 84
	
	private let cornerRadius: CGFloat = 8
	private let selectorStrokeWidth: CGFloat = 4
	private let selectorInset: CGFloat = 5
	private let backgroundColor = Color("ActionButtonBackground")
	
	private let choices: [[T]]
	private let choicesFlat: [T]
	private let elements: [[SegmentedPickerElementView<Text, T>]]
	
	private let onChange: (_ newValue: T) -> Void
	
	init(
		choices: [[T]],
		selectedIndex: Binding<T>,
		onChange: @escaping (_ newValue: T) -> Void = { _ in }
	) {
		self.choices = choices
		self.onChange = onChange
		_selectedIndex = selectedIndex
		var newElements: [[SegmentedPickerElementView<Text, T>]] = []
		var newChoicesFlat: [T] = []
		for r in choices.indices {
			let rowChoices = choices[r]
			var rowElements = [SegmentedPickerElementView<Text, T>]()
			for c in rowChoices.indices {
				let choice = rowChoices[c]
				rowElements.append(SegmentedPickerElementView(id: choice, row: r, col: c) {
					Text(choice.asString)
						.font(.body)
				})
				newChoicesFlat.append(choice)
			}
			newElements.append(rowElements)
		}
		self.elements = newElements
		self.choicesFlat = newChoicesFlat
	}
	
	@State var selectionIndex: CGFloat = 0
	@State var selectionOffsetX: CGFloat = 0
	@State var selectionOffsetY: CGFloat = 0
	@State var selectionWidth: CGFloat = 0
	@State var selectionHeight: CGFloat = 0
	func updateSelectionOffset(id: T, row: Int, col: Int, force: Bool = false) {
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
													self.updateSelectionOffset(id: item.id, row: item.row, col: item.col)
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
//				.padding()
				
//				Text(
//					"selected element: "
//						+ String(self.selectedIndex.asInt)
//						+ " -> "
//						+ self.selectedIndex.asString
//				)
			}
			.onAppear(
				perform: {
					self.width = geo.size.width
					self.height = geo.size.height
					self.updateSelectionOffset(id: self.choicesFlat[0], row: 0, col: 0, force: true)
			}
			)
		}
		.frame(maxWidth: .infinity, maxHeight: CGFloat(60 * self.choices.count), alignment: .top)
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
