import Foundation
import Combine
import SwiftUI

struct SegmentedPickerElementView<Content>: Identifiable, View where Content : View {
	var id: Int
	let content: () -> Content
	
	@inlinable init(id: Int, @ViewBuilder content: @escaping () -> Content) {
		self.id = id
		self.content = content
	}
	
	var body: some View {
		GeometryReader { proxy in
			self.content()//.background(Color.white)
		}//.background(Color.green)
	}
}

struct SegmentedPickerView: View {
	@Environment (\.colorScheme) var colorScheme: ColorScheme
	@State var selectedIndex: Int = 0
	@State var elementWidth: CGFloat = 0
	
	// The values for width and height are arbitrary, and this part
	// of the implementation can be improved (left to the reader).
	private let width: CGFloat = 380
	private let height: CGFloat = 72
	private let cornerRadius: CGFloat = 8
	private let selectorStrokeWidth: CGFloat = 4
	private let selectorInset: CGFloat = 6
	private let backgroundColor = Color(UIColor.lightGray)
	
	private let choices: [String]
	private var elements: [SegmentedPickerElementView<Text>] = [SegmentedPickerElementView<Text>]()
	
	init(choices: [String]) {
		self.choices = choices
		for i in choices.indices {
			self.elements.append(SegmentedPickerElementView(id: i) {
				Text(choices[i])
					.font(.body)
			})
		}
		self.selectedIndex = 0
	}
	
	@State var selectionOffset: CGFloat = 0
	func updateSelectionOffset(id: Int) {
		let widthOfElement = self.width/CGFloat(self.elements.count)
		self.selectedIndex = id
		selectionOffset = CGFloat((widthOfElement * CGFloat(id)) + widthOfElement/2.0)
	}
	
	var body: some View {
		VStack {
			ZStack(alignment: .leading) {
				HStack(alignment: .center, spacing: 0) {
					ForEach(self.elements) { item in
						(item as SegmentedPickerElementView)
							.onTapGesture(perform: {
								withAnimation {
									self.updateSelectionOffset(id: item.id)
								}
							})
					}
				}
				RoundedRectangle(cornerRadius: cornerRadius)
					.stroke(Color.gray, lineWidth: selectorStrokeWidth)
					.foregroundColor(Color.clear)
					.frame(
						width: (width/CGFloat(elements.count)) - 2.0 * selectorInset,
						height: height - 2.0 * selectorInset)
					.position(x: selectionOffset, y: height/2.0)
					.animation(.easeInOut(duration: 0.2))
			}
			.frame(width: width, height: height)
			.background(backgroundColor)
			.cornerRadius(cornerRadius)
			.padding()
			
			Text("selected element: \(selectedIndex) -> \(choices[selectedIndex])")
		}.onAppear(perform: { self.updateSelectionOffset(id: 0) })
	}
}

struct SegmentedPickerView_Previews: PreviewProvider {
	static var previews: some View {
		SegmentedPickerView(choices: FundAction.allCasesAsStrings)
	}
}

//PlaygroundPage.current.setLiveView(SegmentedPickerView(choices: ["A", "B", "C", "D", "E", "F" ]))
