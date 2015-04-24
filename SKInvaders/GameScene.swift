//
//  GameScene.swift
//  SKInvaders
//
//  Created by Riccardo D'Antoni on 15/07/14.
//  Copyright (c) 2014 Razeware. All rights reserved.
//

import SpriteKit
import CoreMotion

class GameScene: SKScene, SKPhysicsContactDelegate {
    let motionManager: CMMotionManager = CMMotionManager()
    var tapQueue: Array<Int> = []
    var contactQueue = Array<SKPhysicsContact>()
    
    enum BulletType {
        case ShipFired
        case InvaderFired
    }
    
  // Private GameScene Properties

    enum InvaderMovementDirection {
        case Right
        case Left
        case DownThenRight
        case DownThenLeft
        case None
    }
    
    //1
    enum InvaderType {
        case A
        case B
        case C
    }
    
    //2
    let kInvaderSize = CGSize(width:24, height:16)
    let kInvaderGridSpacing = CGSize(width:12, height:12)
    let kInvaderRowCount = 6
    let kInvaderColCount = 6
    let kShipSize = CGSize(width:30, height:16)
    let kShipName = "ship"
    let kScoreHudName = "scoreHud"
    let kHealthHudName = "healthHud"
    let kShipFiredBulletName = "shipFiredBullet"
    let kInvaderFiredBulletName = "invaderFiredBullet"
    let kBulletSize = CGSize(width:4, height: 8)
    let kInvaderCategory: UInt32 = 0x1 << 0
    let kShipFiredBulletCategory: UInt32 = 0x1 << 1
    let kShipCategory: UInt32 = 0x1 << 2
    let kSceneEdgeCategory: UInt32 = 0x1 << 3
    let kInvaderFiredBulletCategory: UInt32 = 0x1 << 4
    
    // 3
    let kInvaderName = "invader"
    var contentCreated = false
    // 1
    var invaderMovementDirection: InvaderMovementDirection = .Right
    // 2
    var timeOfLastMove: CFTimeInterval = 0.0
    // 3
    let timePerMove: CFTimeInterval = 1.0
    
  // Object Lifecycle Management
  
  // Scene Setup and Content Creation
  override func didMoveToView(view: SKView) {
    motionManager.startAccelerometerUpdates()
    userInteractionEnabled = true
    physicsWorld.contactDelegate = self

    if (!self.contentCreated) {
        physicsBody = SKPhysicsBody(edgeLoopFromRect: frame)
      self.setupInvaders()
      self.setupShip()
      self.setupHud()
      self.createContent()
      self.physicsBody!.categoryBitMask = kSceneEdgeCategory
      self.contentCreated = true
    }
  }
    
    func makeBulletOfType(bulletType: BulletType) -> SKNode! {
        
        var bullet: SKNode!
        
        switch bulletType {
        case .ShipFired:
            bullet.physicsBody = SKPhysicsBody(rectangleOfSize: bullet.frame.size)
            bullet.physicsBody!.dynamic = true
            bullet.physicsBody!.affectedByGravity = false
            bullet.physicsBody!.categoryBitMask = kShipFiredBulletCategory
            bullet.physicsBody!.contactTestBitMask = kInvaderCategory
            bullet.physicsBody!.collisionBitMask = 0x0
            bullet = SKSpriteNode(color: SKColor.greenColor(), size: kBulletSize)
            bullet.name = kShipFiredBulletName
        case .InvaderFired:
            bullet.physicsBody = SKPhysicsBody(rectangleOfSize: bullet.frame.size)
            bullet.physicsBody!.dynamic = true
            bullet.physicsBody!.affectedByGravity = false
            bullet.physicsBody!.categoryBitMask = kInvaderFiredBulletCategory
            bullet.physicsBody!.contactTestBitMask = kShipCategory
            bullet.physicsBody!.collisionBitMask = 0x0
            bullet = SKSpriteNode(color: SKColor.magentaColor(), size: kBulletSize)
            bullet.name = kInvaderFiredBulletName
            break;
        default:
            bullet = nil
        }
        
        return bullet
    }
    
    func createContent() {
    
//    let invader = SKSpriteNode(imageNamed: "InvaderA_00.png")
    
//    invader.position = CGPoint(x: self.size.width/2, y: self.size.height/2)
    
//    self.addChild(invader)
    
    // black space color
    self.backgroundColor = SKColor.blackColor()
  }

    func makeInvaderOfType(invaderType: InvaderType) -> (SKNode) {
        
        // 1
        var invaderColor: SKColor
        
        switch(invaderType) {
        case .A:
            invaderColor = SKColor.redColor()
        case .B:
            invaderColor = SKColor.greenColor()
        case .C:
            invaderColor = SKColor.blueColor()
        default:
            invaderColor = SKColor.blueColor()
        }
        
        // 2
        let invader = SKSpriteNode(color: invaderColor, size: kInvaderSize)
        invader.name = kInvaderName
        
        invader.physicsBody = SKPhysicsBody(rectangleOfSize: invader.frame.size)
        invader.physicsBody!.dynamic = false
        invader.physicsBody!.categoryBitMask = kInvaderCategory
        invader.physicsBody!.contactTestBitMask = 0x0
        invader.physicsBody!.collisionBitMask = 0x0
        return invader
    }

    func setupInvaders() {
        
        // 1
        let baseOrigin = CGPoint(x:size.width / 3, y:180)
        for var row = 1; row <= kInvaderRowCount; row++ {
            
            // 2
            var invaderType: InvaderType
            if row % 3 == 0 {
                invaderType = .A
            } else if row % 3 == 1 {
                invaderType = .B
            } else {
                invaderType = .C
            }
            
            // 3
            let invaderPositionY = CGFloat(row) * (kInvaderSize.height * 2) + baseOrigin.y
            var invaderPosition = CGPoint(x:baseOrigin.x, y:invaderPositionY)
            
            // 4
            for var col = 1; col <= kInvaderColCount; col++ {
                
                // 5
                var invader = makeInvaderOfType(invaderType)
                invader.position = invaderPosition
                addChild(invader)
                
                // 6
                invaderPosition = CGPoint(x: invaderPosition.x + kInvaderSize.width + kInvaderGridSpacing.width, y: invaderPositionY)
            }
        }
    }

    func setupShip() {
        // 1
        let ship = makeShip()
        
        // 2
        ship.position = CGPoint(x:size.width / 2.0, y:kShipSize.height / 2.0)
        addChild(ship)
    }
    
    func makeShip() -> SKNode {
        let ship = SKSpriteNode(color: SKColor.greenColor(), size: kShipSize)
        ship.name = kShipName
        // 1
        ship.physicsBody!.categoryBitMask = kShipCategory
        // 2
        ship.physicsBody!.contactTestBitMask = 0x0
        // 3
        ship.physicsBody!.collisionBitMask = kSceneEdgeCategory
        
        // 4
        ship.physicsBody!.mass = 0.02
        return ship
    }

    func setupHud() {
        // 1
        let scoreLabel = SKLabelNode(fontNamed: "Courier")
        scoreLabel.name = kScoreHudName
        scoreLabel.fontSize = 25
        
        // 2
        scoreLabel.fontColor = SKColor.greenColor()
        scoreLabel.text = String(format: "Score: %04u", 0)
        
        // 3
        println(size.height)
        scoreLabel.position = CGPoint(x: frame.size.width / 2, y: size.height - (40 + scoreLabel.frame.size.height/2))
        addChild(scoreLabel)
        
        // 4
        let healthLabel = SKLabelNode(fontNamed: "Courier")
        healthLabel.name = kHealthHudName
        healthLabel.fontSize = 25
        
        // 5
        healthLabel.fontColor = SKColor.redColor()
        healthLabel.text = String(format: "Health: %.1f%%", 100.0)
        
        // 6
        healthLabel.position = CGPoint(x: frame.size.width / 2, y: size.height - (80 + healthLabel.frame.size.height/2))
        addChild(healthLabel)
    }
    
  // Scene Update
  
  override func update(currentTime: CFTimeInterval) {
    processUserMotionForUpdate(currentTime)
    moveInvadersForUpdate(currentTime)
    processUserTapsForUpdate(currentTime)
    fireInvaderBulletsForUpdate(currentTime)
    processContactsForUpdate(currentTime)

  }
  
  
  // Scene Update Helpers
    func moveInvadersForUpdate(currentTime: CFTimeInterval) {
        
        // 1
        if (currentTime - timeOfLastMove < timePerMove) {
            determineInvaderMovementDirection()
            return
        }
        
        // 2
        enumerateChildNodesWithName(kInvaderName) {
            node, stop in
            
            switch self.invaderMovementDirection {
            case .Right:
                node.position = CGPoint(x: node.position.x + 10, y: node.position.y)
            case .Left:
                node.position = CGPoint(x: node.position.x - 10, y: node.position.y)
            case .DownThenLeft, .DownThenRight:
                node.position = CGPoint(x: node.position.x, y: node.position.y - 10)
            case .None:
                break
            default:
                break
            }
            
            // 3
            self.timeOfLastMove = currentTime
        }
    }
    
    func processContactsForUpdate(currentTime: CFTimeInterval) {
        
        for contact in self.contactQueue {
            self.handleContact(contact)
            
            if let index = (self.contactQueue as NSArray).indexOfObject(contact) as Int? {
                self.contactQueue.removeAtIndex(index)
            }
        }
    }
    
    func processUserTapsForUpdate(currentTime: CFTimeInterval) {
        // 1
        for tapCount in self.tapQueue {
            if tapCount == 1 {
                // 2
                self.fireShipBullets()
            }
            // 3
            self.tapQueue.removeAtIndex(0)
        }
    }
    
    func processUserMotionForUpdate(currentTime: CFTimeInterval) {
        
        // 1
        let ship = childNodeWithName(kShipName) as! SKSpriteNode
        
        // 2
        if let data = motionManager.accelerometerData {
            
            // 3
            if (fabs(data.acceleration.x) > 0.2) {
                
                // 4 How do you move the ship?
                ship.physicsBody!.applyForce(CGVectorMake(40.0 * CGFloat(data.acceleration.x), 0))
                
            }
        }
    }

    func fireInvaderBulletsForUpdate(currentTime: CFTimeInterval) {
        
        let existingBullet = self.childNodeWithName(kInvaderFiredBulletName)
        
        // 1
        if existingBullet == nil {
            
            var allInvaders = Array<SKNode>()
            
            // 2
            self.enumerateChildNodesWithName(kInvaderName) {
                node, stop in
                
                allInvaders.append(node)
            }
            
            if allInvaders.count > 0 {
                
                // 3
                let allInvadersIndex = Int(arc4random_uniform(UInt32(allInvaders.count)))
                
                let invader = allInvaders[allInvadersIndex]
                
                // 4
                let bullet = self.makeBulletOfType(.InvaderFired)
                bullet.position = CGPoint(x: invader.position.x, y: invader.position.y - invader.frame.size.height / 2 + bullet.frame.size.height / 2)
                
                // 5
                let bulletDestination = CGPoint(x: invader.position.x, y: -(bullet.frame.size.height / 2))
                
                // 6
                self.fireBullet(bullet, toDestination: bulletDestination, withDuration: 2.0, andSoundFileName: "InvaderBullet.wav")
            }
        }
    }
    
    // Invader Movement Helpers
    func determineInvaderMovementDirection() {
        
        // 1
        var proposedMovementDirection: InvaderMovementDirection = invaderMovementDirection
        
        // 2
        enumerateChildNodesWithName(kInvaderName) { node, stop in
            switch self.invaderMovementDirection {
            case .Right:
                //3
                if (CGRectGetMaxX(node.frame) >= node.scene!.size.width - 1.0) {
                    proposedMovementDirection = .DownThenLeft
                    stop.memory = true
                }
            case .Left:
                //4
                if (CGRectGetMinX(node.frame) <= 1.0) {
                    proposedMovementDirection = .DownThenRight
                    
                    stop.memory = true
                }
            case .DownThenLeft:
                //5
                proposedMovementDirection = .Left
                stop.memory = true
            case .DownThenRight:
                //6
                proposedMovementDirection = .Right
                stop.memory = true
            default:
                break
            }
        }
        
        //7
        if (proposedMovementDirection != invaderMovementDirection) {
            invaderMovementDirection = proposedMovementDirection
        }
    }
  // Bullet Helpers
    func fireBullet(bullet: SKNode, toDestination destination:CGPoint, withDuration duration:CFTimeInterval, andSoundFileName soundName: String) {
        
        // 1
        let bulletAction = SKAction.sequence([SKAction.moveTo(destination, duration: duration), SKAction.waitForDuration(3.0/60.0), SKAction.removeFromParent()])
        
        // 2
        let soundAction = SKAction.playSoundFileNamed(soundName, waitForCompletion: true)
        
        // 3
        bullet.runAction(SKAction.group([bulletAction, soundAction]))
        
        // 4
        self.addChild(bullet)
    }
    
    func fireShipBullets() {
        
        let existingBullet = self.childNodeWithName(kShipFiredBulletName)
        
        // 1
        if existingBullet == nil {
            
            if let ship = self.childNodeWithName(kShipName) {
                
                if let bullet = self.makeBulletOfType(.ShipFired) {
                    
                    // 2
                    bullet.position = CGPoint(x: ship.position.x, y: ship.position.y + ship.frame.size.height - bullet.frame.size.height / 2)
                    
                    // 3
                    let bulletDestination = CGPoint(x: ship.position.x, y: self.frame.size.height + bullet.frame.size.height / 2)
                    // 4
                    self.fireBullet(bullet, toDestination: bulletDestination, withDuration: 1.0, andSoundFileName: "ShipBullet.wav")
                    
                }
            }
        }
    }
    
    // User Tap Helpers
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        // Intentional no-op
    }
    
    override func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent)  {
        // Intentional no-op
    }
    
    override func touchesCancelled(touches: Set<NSObject>, withEvent event: UIEvent) {
        // Intentional no-op
    }
    
    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent)  {
        
        if let touch = touches.first as? UITouch {
            
            if (touch.tapCount == 1) {
                
                self.tapQueue.append(1)
            }
        }
    }
    // HUD Helpers
  
  // Physics Contact Helpers
    func didBeginContact(contact: SKPhysicsContact) {
        if contact as SKPhysicsContact? != nil {
            self.contactQueue.append(contact)
        }
    }
    
    func handleContact(contact: SKPhysicsContact) {
        //1
        // Ensure you haven't already handled this contact and removed its nodes
        if (contact.bodyA.node?.parent == nil || contact.bodyB.node?.parent == nil) {
            return
        }
        
        var nodeNames = [contact.bodyA.node!.name!, contact.bodyB.node!.name!]
        
        // 2
        if (nodeNames as NSArray).containsObject(kShipName) && (nodeNames as NSArray).containsObject(kInvaderFiredBulletName) {
            
            // 3
            // Invader bullet hit a ship
            self.runAction(SKAction.playSoundFileNamed("ShipHit.wav", waitForCompletion: false))
            
            contact.bodyA.node!.removeFromParent()
            contact.bodyB.node!.removeFromParent()
            
            
        } else if ((nodeNames as NSArray).containsObject(kInvaderName) && (nodeNames as NSArray).containsObject(kShipFiredBulletName)) {
            
            // 4
            // Ship bullet hit an invader
            self.runAction(SKAction.playSoundFileNamed("InvaderHit.wav", waitForCompletion: false))
            contact.bodyA.node!.removeFromParent()
            contact.bodyB.node!.removeFromParent()
            
        }
    }
    // Game End Helpers
  
}
