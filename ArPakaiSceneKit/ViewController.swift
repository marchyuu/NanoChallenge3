//
//  ViewController.swift
//  ArPakaiSceneKit
//
//  Created by Mellysa Verenna on 11/06/20.
//  Copyright © 2020 Mellysa Verenna. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import RealityKit

class ViewController: UIViewController, ARSCNViewDelegate, SCNPhysicsContactDelegate {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var balloonBtnOutlet: UIButton!
    @IBOutlet weak var scoreLabel: UILabel!
    
    
    var seconds = 30
    var timer = Timer()
    var isTimerRunning = false
    var score = 0
    
    func getUserVector() -> (SCNVector3, SCNVector3) { // (direction, position)
           if let frame = self.sceneView.session.currentFrame {
               // 4x4  transform matrix describing camera in world space
               let mat = SCNMatrix4(frame.camera.transform)
               // orientation of camera in world space
               let dir = SCNVector3(-1 * mat.m31, -1 * mat.m32, -1 * mat.m33)
               // location of camera in world space
               let pos = SCNVector3(mat.m41, mat.m42, mat.m43)
               return (dir, pos)
           }
           return (SCNVector3(0, 0, -1), SCNVector3(0, 0, -0.2))
       }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = false
        
        sceneView.scene.physicsWorld.contactDelegate = self

        
        addTargetNodes()
        
        
        runTimer()
    }
    
    func runTimer(){
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: (#selector(ViewController.updateTimer)), userInfo: nil, repeats: true)
    }
    
    @objc func updateTimer(){
        if seconds == 0 {
            timer.invalidate()
            gameOver()
        }else{
        seconds -= 1
        timerLabel.text = "00 : \(seconds)"
        }
    }
    
    func gameOver(){
        //store the score in UserDefaults
        let defaults = UserDefaults.standard
        defaults.set(score, forKey: "score")
        
        //go back to the Home View Controller
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func balloonBtn(_ sender: Any) {
        fireMissile(type: "ball")
    }
    
    
    func createMissile(type : String)->SCNNode{
        var node = SCNNode()
        
        //using case statement to allow variations of scale and rotations
        switch type {
        case "ball":
            let scene = SCNScene(named: "art.scnassets/Ball DAE.dae")
            node = (scene?.rootNode.childNode(withName: "Solid_001", recursively: true)!)!
            node.scale = SCNVector3(0.1,0.1,0.1)
            node.name = "ball"
            
       
        default:
            node = SCNNode()
        }
        
        //the physics body governs how the object interacts with other objects and its environment
               node.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
               node.physicsBody?.isAffectedByGravity = false
               
               //these bitmasks used to define "collisions" with other objects
               node.physicsBody?.categoryBitMask = CollisionCategory.missileCategory.rawValue
               node.physicsBody?.contactTestBitMask = CollisionCategory.targetCategory.rawValue
              
            //node.physicsBody?.collisionBitMask = CollisionCategory.targetCategory.rawValue
        return node
    }

    func fireMissile(type : String){
        var node = SCNNode()
        node = createMissile(type: type)
        let (direction, position) = self.getUserVector()
        node.position = position
        var nodeDirection = SCNVector3()
        switch type {
        case "ball":
            nodeDirection  = SCNVector3(direction.x*2,direction.y*2,direction.z*2)
            node.physicsBody?.applyForce(nodeDirection, at: SCNVector3(0.1,0,0), asImpulse: true)
        default:
            nodeDirection = direction
        }
        
        node.physicsBody?.applyForce(nodeDirection , asImpulse: true)
        
        sceneView.scene.rootNode.addChildNode(node)
    }
    
    
    
    func addTargetNodes(){
        for index in 1...100 {
            
            var node = SCNNode()
            
            if (index > 9) && (index % 10 == 0) {
                let scene = SCNScene(named: "art.scnassets/Body mesh.dae")
                node = (scene?.rootNode.childNode(withName: "Low_Poly_Characte_000", recursively: true)!)!
                node.scale = SCNVector3(0.3,0.3,0.3)
                node.name = "BodyMesh"
            }
            
            node.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
            node.physicsBody?.isAffectedByGravity = true
            
            //place randomly, within thresholds
            node.position = SCNVector3(randomFloat(min: -5, max: 10),randomFloat(min: -4, max: 5),randomFloat(min: -5, max: 10))
            
            //rotate
            let action : SCNAction = SCNAction.rotate(by: .pi, around: SCNVector3(0, 1, 0), duration: 1.0)
            let forever = SCNAction.repeatForever(action)
            node.runAction(forever)
            
            
            
            //for the collision detection
            node.physicsBody?.categoryBitMask = CollisionCategory.targetCategory.rawValue
            node.physicsBody?.contactTestBitMask = CollisionCategory.missileCategory.rawValue
           // node.physicsBody?.collisionBitMask = CollisionCategory.missileCategory.rawValue
                      
            //add to scene
            sceneView.scene.rootNode.addChildNode(node)
        }
    }
    
    func randomFloat(min: Float, max: Float) -> Float {
        return (Float(arc4random()) / 0xFFFFFFFF) * (max - min) + min
    }
    
   
    
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        
         print("** Collision!! " + contact.nodeA.name! + " hit " + contact.nodeB.name!)
        
        if contact.nodeA.physicsBody?.categoryBitMask == CollisionCategory.targetCategory.rawValue
            || contact.nodeB.physicsBody?.categoryBitMask == CollisionCategory.targetCategory.rawValue {
           
            
            if (contact.nodeA.name! == "BodyMesh" || contact.nodeB.name! == "BodyMesh") {
                score += 5
            }
            
            
            DispatchQueue.main.async {
                contact.nodeA.removeFromParentNode()
                contact.nodeB.removeFromParentNode()
                
                self.scoreLabel.text = String(self.score)
            }
        }
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

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    struct CollisionCategory: OptionSet {
          let rawValue: Int
          static let missileCategory  = CollisionCategory(rawValue: 1 << 0)
          static let targetCategory = CollisionCategory(rawValue: 1 << 1)
      //    static let otherCategory = CollisionCategory(rawValue: 1 << 2)
       }
}
