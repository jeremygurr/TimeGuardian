import Foundation
import Combine
import SwiftUI

struct SegmentedPickerElementView<Content>: Identifiable, Hashable, View where Content : View {
	
	let id: Int
	let row: Int
	let col: Int
	let content: () -> Content
	
	@inlinable init(id: Int, row: Int, col: Int, @ViewBuilder content: @escaping () -> Content) {
		self.id = id
		self.row = row
		self.col = col
		self.content = content
	}
	
	static func == (lhs: SegmentedPickerElementView<Content>, rhs: SegmentedPickerElementView<Content>) -> Bool {
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

struct MultiRowSegmentedPickerView: View {
	@Environment (\.colorScheme) var colorScheme: ColorScheme
	@State var selectedIndex: Int = 0
	@State var elementWidth: CGFloat = 0
	
	// The values for width and height are arbitrary, and this part
	// of the implementation can be improved (left to the reader).
	@State private var width: CGFloat = 380
	@State private var height: CGFloat = 84
	private let cornerRadius: CGFloat = 8
	private let selectorStrokeWidth: CGFloat = 4
	private let selectorInset: CGFloat = 4
	private let backgroundColor = Color(UIColor.lightGray)
	
	private let choices: [[String]]
	private let choicesFlat: [String]
	private let elements: [[SegmentedPickerElementView<Text>]]
	
	init(choices: [[String]]) {
		self.choices = choices
		var i = 0
		var newElements: [[SegmentedPickerElementView<Text>]] = []
		var newChoicesFlat: [String] = []
		for r in choices.indices {
			let rowChoices = choices[r]
			var rowElements = [SegmentedPickerElementView<Text>]()
			for c in rowChoices.indices {
				let choice = rowChoices[c]
				rowElements.append(SegmentedPickerElementView(id: i, row: r, col: c) {
					Text(choice)
						.font(.body)
				})
				newChoicesFlat.append(choice)
				i += 1
			}
			newElements.append(rowElements)
		}
		self.elements = newElements
		self.choicesFlat = newChoicesFlat
		self.selectedIndex = 0
	}
	
	@State var selectionIndex: CGFloat = 0
	@State var selectionOffsetX: CGFloat = 0
	@State var selectionOffsetY: CGFloat = 0
	@State var selectionWidth: CGFloat = 0
	@State var selectionHeight: CGFloat = 0
	func updateSelectionOffset(id: Int, row: Int, col: Int) {
		selectionWidth = self.width/CGFloat(self.elements[row].count)
		selectionHeight = self.height/CGFloat(self.elements.count)
		selectedIndex = id
		selectionOffsetX = CGFloat((selectionWidth * CGFloat(col)) + selectionWidth/2.0)
		selectionOffsetY = CGFloat((selectionHeight * CGFloat(row)) + selectionHeight/2.0)
	}
	
	var body: some View {
		GeometryReader { geo in
			VStack {
				ZStack(alignment: .leading) {
					VStack {
						ForEach(self.elements, id: \.self) { row in
							HStack(alignment: .center, spacing: 0) {
								ForEach(row) { item in
									(item as SegmentedPickerElementView)
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
						.stroke(Color.gray, lineWidth: self.selectorStrokeWidth)
						.foregroundColor(Color.clear)
						.frame(
							width: self.selectionWidth - 2.0 * self.selectorInset,
							height: self.selectionHeight - 2.0 * self.selectorInset
					)
						.position(x: self.selectionOffsetX, y: self.selectionOffsetY)
						.animation(.easeInOut(duration: 0.2))
				}
				.frame(maxWidth: .infinity, minHeight: self.height, maxHeight: self.height)
				.background(self.backgroundColor)
				.cornerRadius(self.cornerRadius)
//				.padding()
				
				Text("selected element: \(self.selectedIndex) -> \(self.choicesFlat[self.selectedIndex])")
			}
			.onAppear(
				perform: {
					self.width = geo.size.width
//					self.height = geo.size.height
					self.updateSelectionOffset(id: 0, row: 0, col: 0)
			}
			)
		}
	}
}

struct SegmentedPickerView_Previews: PreviewProvider {
	static var previews: some View {
		MultiRowSegmentedPickerView(choices: FundAction.allCasesAsStrings)
	}
}
