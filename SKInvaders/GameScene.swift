//
//  GameScene.swift
//  SKInvaders
//

import SpriteKit
import CoreMotion


class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // Game End
    var gameEnding: Bool = false
    
    // Contact
    var contactQueue = Array<SKPhysicsContact>()
    
    // Bitmask Categories
    let kInvaderCategory: UInt32 = 0x1 << 0
    let kShipFiredBulletCategory: UInt32 = 0x1 << 1
    let kShipCategory: UInt32 = 0x1 << 2
    let kSceneEdgeCategory: UInt32 = 0x1 << 3
    let kInvaderFiredBulletCategory: UInt32 = 0x1 << 4
    
    // Bullet type
    enum BulletType {
        case ShipFired
        case InvaderFired
    }
    
    // Invader movement direction
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
    let kInvaderSize = CGSize(width: 24, height: 16)
    let kInvaderGridSpacing = CGSize(width: 12, height: 12)
    let kInvaderRowCount = 6
    let kInvaderColCount = 6
    
    // 3
    let kInvaderName = "invader"
    
    // 4
    let kShipSize = CGSize(width: 30, height: 16)
    let kShipName = "ship"
    
    // 5
    let kScoreHudName = "scoreHud"
    let kHealthHudName = "healthHud"
    
    let kMinInvaderBottomHeight: Float = 32.0
    
    
    // Score and Health
    var score: Int = 0
    var shipHealth: Float = 1.0
    
    // Bullets utils
    let kShipFiredBulletName = "shipFiredBullet"
    let kInvaderFiredBulletName = "invaderFiredBullet"
    let kBulletSize = CGSize(width:4, height: 8)
    
    // Private GameScene Properties
    
    var contentCreated: Bool = false
    
    // Invaders Properties
    var invaderMovementDirection: InvaderMovementDirection = .Right
    var timeOfLastMove: CFTimeInterval = 0.0
    var timePerMove: CFTimeInterval = 1.0
    
    // Accelerometer
    let motionManager: CMMotionManager = CMMotionManager()
    
    // Queue
    var tapQueue: Array<Int> = []
    
    // Object Lifecycle Management
    
    // Scene Setup and Content Creation
    override func didMoveToView(view: SKView) {
        
        if (!self.contentCreated) {
            self.createContent()
            self.contentCreated = true
            
            // Accelerometer starts
            self.motionManager.startAccelerometerUpdates()
            
            // SKScene responds to touches
            self.userInteractionEnabled = true
            
            self.physicsWorld.contactDelegate = self
        }
    }
    
    
    func createContent() {
        
        
        physicsBody = SKPhysicsBody(edgeLoopFromRect: self.frame)
        
        physicsBody!.categoryBitMask = kSceneEdgeCategory
        
        setupInvaders()
        
        setupShip()
        
        setupHud()
        
        // 2 black space color
        self.backgroundColor = SKColor.blackColor()
    }
    
    
    func loadInvaderTexturesOfType(invaderType: InvaderType) -> Array<SKTexture> {
        
        var prefix: String
        
        switch invaderType {
        case .A:
            prefix = "InvaderA"
        case .B:
            prefix = "InvaderB"
        case .C:
            prefix = "InvaderC"
        default:
            prefix = "InvaderC"
        }
        
        // 1
        return [SKTexture(imageNamed: String(format: "%@_00.png", prefix)),
            SKTexture(imageNamed: String(format: "%@_01.png", prefix))]
    }
    
    func makeInvaderOfType(invaderType: InvaderType) -> SKNode {
        
        let invaderTextures = self.loadInvaderTexturesOfType(invaderType)
        
        // 2
        let invader = SKSpriteNode(texture: invaderTextures[0])
        invader.name = kInvaderName
        
        // 3
        invader.runAction(SKAction.repeatActionForever(SKAction.animateWithTextures(invaderTextures, timePerFrame: self.timePerMove)))
        
        // invaders' bitmasks setup
        invader.physicsBody = SKPhysicsBody(rectangleOfSize: invader.frame.size)
        invader.physicsBody!.dynamic = false
        invader.physicsBody!.categoryBitMask = kInvaderCategory
        invader.physicsBody!.contactTestBitMask = 0x0
        invader.physicsBody!.collisionBitMask = 0x0
        
        return invader
    }
    
    
    func setupInvaders() {
        
        // 1
        let baseOrigin = CGPointMake(self.size.width / 3, 180)
        
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
            
            var invaderPosition = CGPointMake(baseOrigin.x, invaderPositionY)
            
            // 4
            for var col = 1; col <= kInvaderColCount; col++ {
                
                // 5
                var invader = self.makeInvaderOfType(invaderType)
                invader.position = invaderPosition
                
                self.addChild(invader)
                
                invaderPosition = CGPointMake(invaderPosition.x + kInvaderSize.width + kInvaderGridSpacing.width, invaderPositionY)
            }
            
        }
        
    }
    
    func setupShip() {
        
        // 1
        let ship: SKNode = self.makeShip()
        
        // 2
        ship.position = CGPointMake(self.size.width / 2, kShipSize.height / 2)
        
        self.addChild(ship)
    }
    
    func makeShip() -> SKNode {
        
        let ship = SKSpriteNode(imageNamed: "Ship.png")
        ship.color = UIColor.greenColor()
        ship.name = kShipName
        
        // Physic
        // 1
        ship.physicsBody = SKPhysicsBody(rectangleOfSize: ship.frame.size)
        
        // 2
        ship.physicsBody!.dynamic = true
        
        // 3
        ship.physicsBody!.affectedByGravity = false
        
        // 4
        ship.physicsBody!.mass = 0.02
        
        // ship's bitmask setup
        // 1
        ship.physicsBody!.categoryBitMask = kShipCategory
        
        // 2
        ship.physicsBody!.contactTestBitMask = 0x0
        
        // 3
        ship.physicsBody!.collisionBitMask = kSceneEdgeCategory
        
        return ship
    }
    
    
    func setupHud() {
        
        let scoreLabel = SKLabelNode(fontNamed: "Courier")
        
        // 1
        scoreLabel.name = kScoreHudName
        scoreLabel.fontSize = 25
        
        // 2
        scoreLabel.fontColor = SKColor.greenColor()
        scoreLabel.text = String(format: "Score: %04u", 0)
        
        // 3
        println(self.size.height)
        scoreLabel.position = CGPointMake(self.frame.size.width / 2, self.size.height - (40 + scoreLabel.frame.size.height/2))
        self.addChild(scoreLabel)
        
        let healthLabel = SKLabelNode(fontNamed: "Courier")
        
        // 4
        healthLabel.name = kHealthHudName
        healthLabel.fontSize = 25
        
        // 5
        healthLabel.fontColor = SKColor.redColor()
        healthLabel.text = String(format: "Health: %.1f%%", self.shipHealth * 100.0)
        
        // 6
        healthLabel.position = CGPointMake(self.frame.size.width / 2, self.size.height - (80 + healthLabel.frame.size.height / 2))
        self.addChild(healthLabel)
    }
    
    
    func makeBulletOfType(bulletType: BulletType) -> SKNode! {
        
        var bullet: SKNode!
        
        switch bulletType {
        case .ShipFired:
            bullet = SKSpriteNode(color: SKColor.greenColor(), size: kBulletSize)
            bullet.name = kShipFiredBulletName
            
            bullet.physicsBody = SKPhysicsBody(rectangleOfSize: bullet.frame.size)
            bullet.physicsBody!.dynamic = true
            bullet.physicsBody!.affectedByGravity = false
            bullet.physicsBody!.categoryBitMask = kShipFiredBulletCategory
            bullet.physicsBody!.contactTestBitMask = kInvaderCategory
            bullet.physicsBody!.collisionBitMask = 0x0
            
        case .InvaderFired:
            bullet = SKSpriteNode(color: SKColor.magentaColor(), size: kBulletSize)
            bullet.name = kInvaderFiredBulletName
            
            bullet.physicsBody = SKPhysicsBody(rectangleOfSize: bullet.frame.size)
            bullet.physicsBody!.dynamic = true
            bullet.physicsBody!.affectedByGravity = false
            bullet.physicsBody!.categoryBitMask = kInvaderFiredBulletCategory
            bullet.physicsBody!.contactTestBitMask = kShipCategory
            bullet.physicsBody!.collisionBitMask = 0x0
            
        default:
            bullet = nil
        }
        
        return bullet
    }
    
    
    // Scene Update
    
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        
        if self.isGameOver() {
            
            self.endGame()
        }
        
        self.processContactsForUpdate(currentTime)
        
        self.processUserTapsForUpdate(currentTime)
        
        self.processUserMotionForUpdate(currentTime)
        
        self.moveInvadersForUpdate(currentTime)
        
        self.fireInvaderBulletsForUpdate(currentTime)
    }
    
    
    // Scene Update Helpers
    
    func moveInvadersForUpdate(currentTime: CFTimeInterval) {
        
        // 1
        if (currentTime - self.timeOfLastMove < self.timePerMove) {
            return
        }
        
        // logic to change movement direction
        self.determineInvaderMovementDirection()
        
        // 2
        enumerateChildNodesWithName(kInvaderName) {
            node, stop in
            
            switch self.invaderMovementDirection {
            case .Right:
                node.position = CGPointMake(node.position.x + 10, node.position.y)
            case .Left:
                node.position = CGPointMake(node.position.x - 10, node.position.y)
            case .DownThenLeft, .DownThenRight:
                node.position = CGPointMake(node.position.x, node.position.y - 10)
            case .None:
                break
            default:
                break
            }
            
            // 3
            self.timeOfLastMove = currentTime
            
        }
    }
    
    func secureChildNodeWithName(name: String) -> SKSpriteNode! {
        
        var shipNode: SKSpriteNode!
        
        // enumerate to find the ship node
        self.enumerateChildNodesWithName(kShipName) {
            node, stop in
            
            if let aNode = node {
                
                shipNode = aNode as! SKSpriteNode
            }
        }
        
        // if found return it
        if shipNode != nil {
            return shipNode
        } else {
            return nil
        }
    }
    
    func processUserMotionForUpdate(currentTime: CFTimeInterval) {
        
        // 1
        if let ship = self.secureChildNodeWithName(kShipName) as SKSpriteNode! {
            // 2
            if let data = self.motionManager.accelerometerData {
                
                // 3
                if fabs(data.acceleration.x) > 0.2 {
                    
                    // 4 How do you move the ship?
                    ship.physicsBody!.applyForce(CGVectorMake(40.0 * CGFloat(data.acceleration.x), 0))
                }
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
    
    
    func processContactsForUpdate(currentTime: CFTimeInterval) {
        
        for contact in self.contactQueue {
            self.handleContact(contact)
            
            if let index = (self.contactQueue as NSArray).indexOfObject(contact) as Int? {
                self.contactQueue.removeAtIndex(index)
            }
        }
    }
    
    // Invader Movement Helpers
    
    func adjustInvaderMovementToTimePerMove(newTimerPerMove: CFTimeInterval) {
        
        // 1
        if newTimerPerMove <= 0 {
            return
        }
        
        // 2
        let ratio: CGFloat = CGFloat(self.timePerMove / newTimerPerMove)
        self.timePerMove = newTimerPerMove
        
        enumerateChildNodesWithName(kInvaderName) {
            node, stop in
            // 3
            node.speed = node.speed * ratio
        }
    }
    
    func determineInvaderMovementDirection() {
        
        // 1
        var proposedMovementDirection: InvaderMovementDirection = self.invaderMovementDirection
        
        // 2
        enumerateChildNodesWithName(kInvaderName) {
            node, stop in
            
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
                proposedMovementDirection = .Left
                
                // Add the following line
                self.adjustInvaderMovementToTimePerMove(self.timePerMove * 0.8)
                
                stop.memory = true
                
            case .DownThenRight:
                proposedMovementDirection = .Right
                
                // Add the following line
                self.adjustInvaderMovementToTimePerMove(self.timePerMove * 0.8)
                
                stop.memory = true
                
            default:
                break
                
            }
            
        }
        
        //7
        if (proposedMovementDirection != self.invaderMovementDirection) {
            self.invaderMovementDirection = proposedMovementDirection
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
    
    func adjustScoreBy(points: Int) {
        
        self.score += points
        
        let score = self.childNodeWithName(kScoreHudName) as! SKLabelNode
        
        score.text = String(format: "Score: %04u", self.score)
    }
    
    func adjustShipHealthBy(healthAdjustment: Float) {
        
        // 1
        self.shipHealth = max(self.shipHealth + healthAdjustment, 0)
        
        let health = self.childNodeWithName(kHealthHudName) as! SKLabelNode
        
        health.text = String(format: "Health: %.1f%%", self.shipHealth * 100)
        
    }
    
    // Physics Contact Helpers
    
    func didBeginContact(contact: SKPhysicsContact) {
        
        if contact as SKPhysicsContact? != nil {
            self.contactQueue.append(contact)
        }
    }
    
    func handleContact(contact: SKPhysicsContact) {
        
        // Ensure you haven't already handled this contact and removed its nodes
        if (contact.bodyA.node?.parent == nil || contact.bodyB.node?.parent == nil) {
            return
        }
        
        var nodeNames = [contact.bodyA.node!.name!, contact.bodyB.node!.name!]
        
        if (nodeNames as NSArray).containsObject(kShipName) && (nodeNames as NSArray).containsObject(kInvaderFiredBulletName) {
            
            // Invader bullet hit a ship
            self.runAction(SKAction.playSoundFileNamed("ShipHit.wav", waitForCompletion: false))
            
            // 1
            self.adjustShipHealthBy(-0.334)
            
            if self.shipHealth <= 0.0 {
                
                // 2
                contact.bodyA.node!.removeFromParent()
                contact.bodyB.node!.removeFromParent()
                
            } else {
                
                // 3
                let ship = self.childNodeWithName(kShipName)
                
                ship!.alpha = CGFloat(self.shipHealth)
                
                if contact.bodyA.node == ship {
                    
                    contact.bodyB.node!.removeFromParent()
                    
                } else {
                    
                    contact.bodyA.node!.removeFromParent()
                }
                
            }
            
        } else if (nodeNames as NSArray).containsObject(kInvaderName) && (nodeNames as NSArray).containsObject(kShipFiredBulletName) {
            
            // Ship bullet hit an invader
            self.runAction(SKAction.playSoundFileNamed("InvaderHit.wav", waitForCompletion: false))
            contact.bodyA.node!.removeFromParent()
            contact.bodyB.node!.removeFromParent()
            
            // 4
            self.adjustScoreBy(100)
        }
    }
    
    
    
    
    
    // Game End Helpers
    
    func isGameOver() -> Bool {
        
        // 1
        let invader = self.childNodeWithName(kInvaderName)
        
        // 2
        var invaderTooLow = false
        
        enumerateChildNodesWithName(kInvaderName) {
            node, stop in
            
            if Float(CGRectGetMinY(node.frame)) <= self.kMinInvaderBottomHeight {
                
                invaderTooLow = true
                stop.memory = true
            }
        }
        
        // 3
        let ship = self.childNodeWithName(kShipName)
        
        // 4
        return invader == nil || invaderTooLow || ship == nil
    }
    
    func endGame() {
        // 1
        if !self.gameEnding {
            
            self.gameEnding = true
            
            // 2
            self.motionManager.stopAccelerometerUpdates()
            
            // 3
            let gameOverScene: GameOverScene = GameOverScene(size: self.size)
            
            view!.presentScene(gameOverScene, transition: SKTransition.doorsOpenHorizontalWithDuration(1.0))
        }
    }
    
    
}
