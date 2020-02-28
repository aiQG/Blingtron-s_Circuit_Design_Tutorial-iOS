//
//  GameScene.swift
//  Blingtron-s_Circuit_Design_Tutorial-iOS
//
//  Created by 周测 on 2/28/20.
//  Copyright © 2020 aiQG_. All rights reserved.
//

import SpriteKit
import GameplayKit
import simd //矩阵、向量运算

class GameScene: SKScene {
	
	private var unSelectedPointColor: SKKeyframeSequence? = nil
	private var SelectedPointColor: SKKeyframeSequence? = nil
	private var firstPoint: SKEmitterNode? = nil
	private var secondPoint: SKEmitterNode? = nil
	private let CrossLineColor: UIColor = UIColor(red: 1, green: 0.1, blue: 0.1, alpha: 0.7)
	private let notCrossLineColor: UIColor = UIColor(red: 0.2, green: 0.5, blue: 1, alpha: 0.7)
	
	private var success: Bool = true
	private var OKButton: SKSpriteNode =
		SKSpriteNode(color: UIColor(red: 0.2, green: 0.5, blue: 1, alpha: 1),
					 size: CGSize(width: 100, height: 50))
	
	let pointList = [
		CGPoint(x:  200, y:  200),	//0
		CGPoint(x:   0, y:  200),	//1
		CGPoint(x: -100, y:  200),	//2
		CGPoint(x: -200, y:  200),	//3
		CGPoint(x: -200, y: -200),	//4
		CGPoint(x: 0, y: -200),	//5
		CGPoint(x:  100, y: -200),	//6
		CGPoint(x:  200, y: -200),	//7
	]
	let connect: [(Int,Int)] = [
		(0,1),
		(1,2),
		(2,3),
		(3,4),
		(4,5),
		(5,6),
		(6,7),
		(7,0),
		(1,6),
		(2,5),
	]
	
	var lineArr: [SKShapeNode] = []
	
	
	override func didMove(to view: SKView) {
		// 创建button
		let label = SKLabelNode(text: "GO!")
		label.fontSize = 50
		label.position = CGPoint(x: 0, y: -OKButton.size.height/2)
		OKButton.addChild(label)
		OKButton.name = "OKButton"
		label.name = OKButton.name
		OKButton.position = CGPoint(x: 150, y: -60)
		OKButton.zPosition = 2
		self.addChild(OKButton)
		// 创建点
		for index in 0 ..< pointList.count {
			let node = SKEmitterNode(fileNamed: "Point")
			node?.position = pointList[index]
			node?.zPosition = 1
			node?.name = "\(index)"
			self.addChild(node!)
			unSelectedPointColor = node!.particleColorSequence
		}
		
		// 遍历点 并连起 线保存到数组
		for i in 0 ..< connect.count {
			//pA点为name小的, pB为name大的
			let pA = childNode(withName: connect[i].0 < connect[i].1 ? "\(connect[i].0)" : "\(connect[i].1)")
			let pB = childNode(withName: connect[i].0 > connect[i].1 ? "\(connect[i].0)" : "\(connect[i].1)")
			
			let line = SKShapeNode()
			let path = CGMutablePath()
			path.move(to: pA!.position)
			path.addLine(to: pB!.position)
			line.path = path
			line.strokeColor = notCrossLineColor
			line.lineWidth = 3
			line.name = "\(pA!.name!)-\(pB!.name!)"
			addChild(line)
			lineArr.append(line)
		}
		
		// 随机打乱
		randomSwap(times: 10)
	}
	
	
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		let touch = touches.first
		if let location = touch?.location(in: self) {
			guard self.nodes(at: location).count >= 1 else {
				return
			}
			let node = self.nodes(at: location)[0]
			if node.name == "OKButton" {
				if success {
					print("success")
				}
				return
			} else {
				guard let beSelectedPoint = node as? SKEmitterNode else {
					return
				}
				beSelectedPoint.particleColorSequence = beSelectedPoint.particleColorSequence == SelectedPointColor ? unSelectedPointColor : SelectedPointColor
				
				if firstPoint == nil && beSelectedPoint.particleColorSequence == SelectedPointColor  {
					firstPoint = beSelectedPoint
				} else if firstPoint == beSelectedPoint {
					firstPoint = nil
				} else if firstPoint != beSelectedPoint {
					if beSelectedPoint.particleColorSequence == SelectedPointColor {
						pointSwap(point1: firstPoint!, point2: beSelectedPoint)
					}
				}
			}
		}
	}
	
	private func pointSwap(point1:SKEmitterNode, point2:SKEmitterNode, duration: Double = 0.3) {
		//lines
		for i in lineArr {
			let topath = CGMutablePath()
			//线起点
			if i.name!.hasPrefix(point1.name!) {
				topath.move(to: point2.position)
			} else if i.name!.hasPrefix(point2.name!) {
				topath.move(to: point1.position)
			} else {
				topath.move(to: i.path!.points.first!)
			}
			//线终点
			if i.name!.hasSuffix(point1.name!) {
				topath.addLine(to: point2.position)
			} else if i.name!.hasSuffix(point2.name!) {
				topath.addLine(to: point1.position)
			} else {
				topath.addLine(to: i.path!.points.last!)
			}
			
			i.run(SKAction.lineAnim(fromPath: i.path!, toPath: topath, duration: duration))
		}
		
		//points
		let point1Position = SKAction.move(
			to: CGPoint(x: point1.position.x, y: point1.position.y),
			duration: duration)
		let point2Position = SKAction.move(
			to: CGPoint(x: point2.position.x, y: point2.position.y),
			duration: duration)
		point1.run(point2Position)
		point2.run(point1Position)
		
		point1.particleColorSequence = unSelectedPointColor
		point2.particleColorSequence = unSelectedPointColor
		firstPoint = nil
		
	}
	
	// 随机打乱
	private func randomSwap(times: Int) {
		for _ in 0 ..< times {
			let n0 = Int.random(in: 0..<pointList.count)
			var n1 = Int.random(in: 0..<pointList.count)
			while n0 == n1 {
				n1 = Int.random(in: 0..<pointList.count)
			}
			let p0 = childNode(withName: String(n0)) as! SKEmitterNode
			let p1 = childNode(withName: String(n1)) as! SKEmitterNode
			
			for i in lineArr {
				let topath = CGMutablePath()
				//线起点
				if i.name!.hasPrefix(p0.name!) {
					topath.move(to: p1.position)
				} else if i.name!.hasPrefix(p1.name!) {
					topath.move(to: p0.position)
				} else {
					topath.move(to: i.path!.points.first!)
				}
				//线终点
				if i.name!.hasSuffix(p0.name!) {
					topath.addLine(to: p1.position)
				} else if i.name!.hasSuffix(p1.name!) {
					topath.addLine(to: p0.position)
				} else {
					topath.addLine(to: i.path!.points.last!)
				}
				i.path = topath
			}
			
			swap(&p0.position, &p1.position)
		}
	}
	
	
	override func update(_ currentTime: TimeInterval) {
		// 实时更新线的颜色(是否交叉)
		success = true
		for i in 0 ..< lineArr.count {
			var flag: Bool = false
			for j in 0 ..< lineArr.count {
				if i == j {
					continue
				}
				let selfPathPoint = lineArr[i].path?.points
				let otherPathPoint = lineArr[j].path?.points
				// 计算selfPath和otherPath是否交叉
				let v1 = simd_double2(x: Double((selfPathPoint?.last!.x)! - (selfPathPoint?.first!.x)!),
									  y: Double((selfPathPoint?.last!.y)! - (selfPathPoint?.first!.y)!))
				let v2 = simd_double2(x: Double((otherPathPoint?.first!.x)! - (selfPathPoint?.first!.x)!),
									  y: Double((otherPathPoint?.first!.y)! - (selfPathPoint?.first!.y)!))
				let v3 = simd_double2(x: Double((otherPathPoint?.last!.x)! - (selfPathPoint?.first!.x)!),
									  y: Double((otherPathPoint?.last!.y)! - (selfPathPoint?.first!.y)!))
				let x0 = simd_double2x2([v1, v2]).determinant
				let x1 = simd_double2x2([v1, v3]).determinant
				let result0 = x0 * x1
				
				let v4 = simd_double2(x: Double((otherPathPoint?.last!.x)! - (otherPathPoint?.first!.x)!),
									  y: Double((otherPathPoint?.last!.y)! - (otherPathPoint?.first!.y)!))
				let v5 = simd_double2(x: Double((selfPathPoint?.first!.x)! - (otherPathPoint?.first!.x)!),
									  y: Double((selfPathPoint?.first!.y)! - (otherPathPoint?.first!.y)!))
				let v6 = simd_double2(x: Double((selfPathPoint?.last!.x)! - (otherPathPoint?.first!.x)!),
									  y: Double((selfPathPoint?.last!.y)! - (otherPathPoint?.first!.y)!))
				let x2 = simd_double2x2([v4, v5]).determinant
				let x3 = simd_double2x2([v4, v6]).determinant
				let result1 = x2 * x3
				// result < 0 为相交
				flag = flag || (result0 < 0 && result1 < 0)
				
				// 判断两条线段在同一条直线上的情况
				if (result0 == 0 && result1 == 0){
					if(lineArr[i].path!.contains(otherPathPoint!.first!)
						&& lineArr[i].path!.contains(otherPathPoint!.last!))
						|| (lineArr[j].path!.contains(selfPathPoint!.first!)
							&& lineArr[j].path!.contains(selfPathPoint!.last!)){	// 两条线段中的一条完全包含另一条
						flag = flag || true
					} else if (selfPathPoint!.first! != otherPathPoint!.first!
						&& selfPathPoint!.first! != otherPathPoint!.last!
						&& selfPathPoint!.last! != otherPathPoint!.first!
						&& selfPathPoint!.last! != otherPathPoint!.last!)
						&& (lineArr[i].path!.contains(otherPathPoint!.first!)
							|| lineArr[i].path!.contains(otherPathPoint!.last!)){	// 两条线段中的一条部分包含另一条(不含端点)(与上面判断存在交集)
						flag = flag || true
					}
				}
			}
			lineArr[i].strokeColor = flag ? CrossLineColor : notCrossLineColor
			success = flag ? success && false : success && true
		}
	}
}



//导出CGPath的点数组
extension CGPath {
	var points: [CGPoint] {
		
		var arrPoints: [CGPoint] = []
		
		self.applyWithBlock { element in
			switch element.pointee.type
			{
			case .moveToPoint, .addLineToPoint:
				arrPoints.append(element.pointee.points.pointee)
				
			case .addQuadCurveToPoint:
				arrPoints.append(element.pointee.points.pointee)
				arrPoints.append(element.pointee.points.advanced(by: 1).pointee)
				
			case .addCurveToPoint:
				arrPoints.append(element.pointee.points.pointee)
				arrPoints.append(element.pointee.points.advanced(by: 1).pointee)
				arrPoints.append(element.pointee.points.advanced(by: 2).pointee)
				
			default:
				break
			}
		}
		
		return arrPoints
	}
}

extension SKAction {
	// 线动画
	static func lineAnim(fromPath: CGPath, toPath: CGPath, duration: Double = 0.5) -> SKAction {
		return SKAction.customAction(withDuration: duration){ (node: SKNode!, elapsedTime: CGFloat) -> Void in
			let fraction = CGFloat(elapsedTime / CGFloat(duration))
			let start = fromPath
			let end = toPath
			let trans = CGMutablePath()
			trans.move(to: CGPoint(
				x: start.points.first!.x + (end.points.first!.x - start.points.first!.x) * fraction,
				y: start.points.first!.y + (end.points.first!.y - start.points.first!.y) * fraction))
			
			trans.addLine(to: CGPoint(x: start.points.last!.x + (end.points.last!.x - start.points.last!.x) * fraction,
									  y: start.points.last!.y + (end.points.last!.y - start.points.last!.y) * fraction))
			
			(node as? SKShapeNode)?.path = trans
		}
	}
}
