# CubeTransitionInfiniteViewSwift
An infinite scroll view to support 3D-Cube transition animation, like Intagram stories


## Usage 

Add dependency in the Podfile 

```
  pod 'CubeTransitionInfiniteViewSwift', :git => 'git@github.com:sueLan/CubeTransitionInfiniteViewSwift.git'
```



### Methods: 
```swift
public protocol CubeTransitionViewDelegate: NSObject {
    func pageView(atIndex: Int) -> UIView
    func numberofPages() -> Int
    func pageDidChanged(index: Int, direction: Direction)
}
```


| Method            | Des                                          |
|-------------------|----------------------------------------------|
| func reloadData() | We have to call it to render the first page. |

### property:

| name  |  des |
|---|---|
| delegate  |   |
|  offsetCachedPageNumber |  The default value is 1, The number of rendered views is 2* ${offsetCachedPageNumber} + 1  |
| pageFlipAnimationDuration  | The duration of the cube transition animation  |
| pageResetAnmationDuration  |   |
| gestureSpeedForPageFlipping  | A threshold of gesture speed to determine wether flipping page or not  |
| gestureDistanceForPageFlipping | A threshold of gesture translate distance to determine wether flipping page or not |





## Example 

```swift 
class ViewController: UIViewController, CubeTransitionViewDelegate {
    func pageView(atIndex: Int) -> UIView {
          let view = UIView.init(frame: CGRect.init(x: 0, y: 0, width: transitionView.bounds.size.width, height: transitionView.bounds.size.height))
          let color = pageData[atIndex]
          view.backgroundColor = color
          return view
      }
      
      func numberofPages() -> Int {
          return pageData.count
      }
      
      func pageDidChanged(index: Int, direction: Direction) {
          print("index", index)
      }
      
      private var pageData = [Int: UIColor]()
      private var transitionView: CubeTransitionInfiniteView = CubeTransitionInfiniteView.init()
      
      override func viewDidLoad() {
          super.viewDidLoad()
          // Do any additional setup after loading the view.
          self.initData()
          self.initViews()
      }
      
      override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?)   {
            super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        }
      
      required init?(coder: NSCoder) {
            super.init(coder: coder)
      }
      
      func initData() {
          pageData[0] = UIColor.orange
          pageData[1] = UIColor.red
          pageData[2] = UIColor.yellow
          pageData[3] = UIColor.blue
          pageData[4] = UIColor.green
      }
 
      func initViews() {
        let frame: CGRect = CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height)
        transitionView = CubeTransitionInfiniteView.init(frame: frame)
          transitionView.delegate = self as CubeTransitionViewDelegate
          self.view .addSubview(transitionView)
          transitionView.reloadData();
      }
}

``` 
