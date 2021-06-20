//
//  ViewController.swift
//  MeasurementApp
//
//  Created by Alexander Römer on 20.06.21.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    
    private var dotNodes = [SCNNode]()
    private var textNodes = SCNNode()
    private var meterValue: Double?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        debugPrint("Dot counts", dotNodes.count)
        if dotNodes.count >= 2 {
            for dot in dotNodes {
                dot.removeFromParentNode()
            }
            dotNodes = [SCNNode]()
        }
    
        if let touchLocation = touches.first?.location(in: sceneView) {
//            let hitTestResult = sceneView.hitTest(touchLocation, types: .featurePoint)
//            if let hitResult = hitTestResult.first {
//                addDot(at: hitResult)
//            }
            let estimatedPlane: ARRaycastQuery.Target = .estimatedPlane
            let alignment: ARRaycastQuery.TargetAlignment = .any

            let query: ARRaycastQuery? = sceneView.raycastQuery(from: touchLocation, allowing: estimatedPlane, alignment: alignment)

            if let nonOptQuery: ARRaycastQuery = query {
                let result: [ARRaycastResult] = sceneView.session.raycast(nonOptQuery)
                guard let rayCast: ARRaycastResult = result.first else { return }
                addDot(at: rayCast)
            }
        } else {
            debugPrint("No touchLocation found")
        }
        
        
    }
    
    
    //hitResult: ARHitTestResult ARRaycastResult
    private func addDot(at hitResult: ARRaycastResult) {
        let dotGeometry = SCNSphere(radius: 0.005)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.red
        dotGeometry.materials = [material]
        
        let dotNode = SCNNode(geometry: dotGeometry)
        dotNode.position = SCNVector3(hitResult.worldTransform.columns.3.x, hitResult.worldTransform.columns.3.y, hitResult.worldTransform.columns.3.z)
        
        sceneView.scene.rootNode.addChildNode(dotNode)
        
        dotNodes.append(dotNode)
        
        if dotNodes.count >= 2 {
            calculate()
        }
    }
    
    private func calculate() {
        let start = dotNodes[0]
        let end = dotNodes[1]
        
        debugPrint("Start", start)
        debugPrint("End", end)

        let distance = sqrt(
            pow(end.position.x - start.position.x, 2) +
            pow(end.position.y - start.position.y, 2) +
            pow(end.position.z - start.position.z, 2)
        )
        
        meterValue = Double(abs(distance))
        
        let heightMeter = Measurement(value: meterValue ?? 0, unit: UnitLength.meters)
        //let heightInches = heightMeter.converted(to: UnitLength.inches)
        let heightCentimeter = heightMeter.converted(to: UnitLength.centimeters)

        let value = "\(heightCentimeter)"
        let finalMeasurement = String(value.prefix(6))
        updateText(text: finalMeasurement, atPosition: end.position)
    }
    
    private func updateText(text: String, atPosition position: SCNVector3) {
        textNodes.removeFromParentNode()
        let textGeometry = SCNText(string: text, extrusionDepth: 1.0)
        textGeometry.firstMaterial?.diffuse.contents = UIColor.red
        textNodes = SCNNode(geometry: textGeometry)
        textNodes.position = SCNVector3(x: position.x, y: position.y + 0.01, z: position.z)
        textNodes.scale = SCNVector3(x: 0.01, y: 0.01, z: 0.01)
        sceneView.scene.rootNode.addChildNode(textNodes)
    }
    
    
    
}
