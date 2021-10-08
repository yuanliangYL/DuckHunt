//
//  ViewController.swift
//  DuckHunt
//
//  Created by AlbertYuan on 2021/10/8.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    @IBOutlet weak var gun: UIImageView!

    @IBOutlet weak var shortCenter: UIImageView!

    @IBOutlet var AllDucks: [Duck]!

    @IBOutlet var Allcloud: [UIImageView]!


    @IBOutlet weak var score: UILabel!
    @IBOutlet weak var timeLabel: UILabel!

    var duckTimer :Timer?
    var timeTimer :Timer?

    var userscore:Int = 0{
        didSet{
            score.text = "score:\(userscore)"
        }
    }
//    属性观察器的应用
    var timeLeft:Int = 30 {
        didSet{
            timeLabel.text = "Time:\(timeLeft)"

            if timeLeft == 0 {
                gameOver()
            }
        }
    }

    @IBOutlet weak var restartBtn: UIButton!

    var backMusicPlayer:AVAudioPlayer?
    var gunShortPlayer:AVAudioPlayer?
    var duckQuackPlayer:AVAudioPlayer?
    var duckHitPlayer:AVAudioPlayer?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        backMusicPlayer = createPlayer(finename: "background", loop: true)
        backMusicPlayer?.play()

        cloudMove()

        gameStart()

    }

    func createPlayer(finename:String, loop:Bool) -> AVAudioPlayer? {

        if let filePath = Bundle.main.path(forResource: finename, ofType: "mp3"){

            let fileurl = URL(fileURLWithPath: filePath)
            let audioPlayer = try? AVAudioPlayer(contentsOf: fileurl)
            audioPlayer?.numberOfLoops = loop ? -1 : 0
            return audioPlayer

        }

        return nil
    }

    func duckFly(){
        for duck in AllDucks {
            duck.image = UIImage.animatedImageNamed( "duckfly_0", duration: 0.6)
        }
    }

    @objc func updateGameTime(){

        if timeLeft <= 0 {
            return
        }

        timeLeft -= 1
    }

    func gameOver(){
        timeTimer?.invalidate()
        timeTimer = nil
        duckTimer?.invalidate()
        duckTimer = nil
        restartBtn.isHidden = false

    }

    @objc func moveDuck(sender: Timer){

        for  duck in AllDucks {

            let originLocation = duck.frame.origin

            //生死判断
            if duck.isDuckDead {

                var newY:CGFloat = duck.frame.origin.y

                if newY >= UIScreen.main.bounds.height - duck.frame.height {
                    newY = UIScreen.main.bounds.height - duck.frame.height

                    if !duck.isFalling {

                        UIView.animate(withDuration: 0.6) {
                            duck.alpha = 0
                        }completion: { finished in
                            self.reviceDuck(duck: duck)
                        }

                        duckHitPlayer = createPlayer(finename: "duckgroundhit", loop: false)
                        duckHitPlayer?.play()
                    }
                    duck.isFalling = true


                }else{
                    newY += 50
                }
                duck.frame.origin =  CGPoint(x: duck.frame.origin.x, y:newY)

            }else{

                let movePoint = arc4random()%15+5
                var newX:CGFloat

                if originLocation.x > UIScreen.main.bounds.maxX {
                    newX = -30
                }else{
                    newX =  originLocation.x + CGFloat(movePoint)
                }
                duck.frame.origin =  CGPoint(x: newX, y: originLocation.y)
            }

        }

    }

    func cloudMove(){

        Allcloud.forEach { cloud in
            self.cloudAnimation(cloud: cloud)
        }
    }

    func cloudAnimation(cloud:UIImageView){

        let cloudSpeed = cloud.frame.size.width / view.frame.width
        let duration = (view.frame.width - cloud.frame.origin.x) * cloudSpeed / 5
        
        UIView.animate(withDuration: TimeInterval(duration), delay: 0.0, options: [.curveLinear], animations: {
            cloud.frame.origin.x = self.view.frame.width
        }, completion: { _ in
            cloud.frame.origin.x -= self.view.frame.width
            self.cloudAnimation(cloud: cloud)
        })
    }

    @IBAction func clickBirdAction(_ sender: UITapGestureRecognizer) {

        if timeLeft == 0 {
            return
        }

        gunShortPlayer = createPlayer(finename: "gunshot", loop: false)
        gunShortPlayer?.play()

        let touchPoint = sender.location(in: view)
        shortCenter.center = touchPoint
        print("user click \(touchPoint)")

        //三角函数计算角度
        let ditX = touchPoint.x - UIScreen.main.bounds.width / 2
        let ditY = UIScreen.main.bounds.maxY - touchPoint.y

        //设置position位置与anchorpoint
//        gun.layer.position = CGPoint(x: UIScreen.main.bounds.width / 2, y: barrerMaxY)
//        gun.layer.anchorPoint = CGPoint(x: 0.5, y: 1.0)

        gun.transform = CGAffineTransform(rotationAngle: atan(ditX / ditY))

        collisionDuck(by: touchPoint)

    }


    func collisionDuck(by touchPoint:CGPoint){

        //击中
        let hitPoint = CGRect(x: touchPoint.x - 30, y:  touchPoint.y - 30, width: 60, height: 60)

        // 擦肩而过
        let scarePoint = CGRect(x: touchPoint.x - 50, y:  touchPoint.y - 50, width: 100, height: 100)

        for duck in AllDucks {
            if hitPoint.contains(duck.frame) {

                duck.image = UIImage(named: "duckdrop")
                duck.isDuckDead = true


                //积分
                userscore += 1
                timeLeft += 2

            }else if scarePoint.contains(duck.frame){

                duck.image = UIImage.animatedImageNamed("duckfrighten_0", duration: 0.7)
                self.perform(#selector(resetDuck(duck:)), with: duck, afterDelay: 2)

                duckQuackPlayer = createPlayer(finename: "duckquack", loop: false)
                duckQuackPlayer?.play()

            }
            else{
                //do nothing
            }
        }

    }

    @objc func resetDuck(duck:Duck){
        //fly again
        if duck.isDuckDead {
            return
        }
        
        duck.image = UIImage.animatedImageNamed( "duckfly_0", duration: 0.6)
    }

    @objc func reviceDuck(duck:Duck){

        duck.alpha = 1
        duck.image = UIImage.animatedImageNamed( "duckfly_0", duration: 0.6)
        duck.isDuckDead = false
        duck.isFalling = false

        let y = arc4random()%(UInt32(UIScreen.main.bounds.height) / 2) + 30

        duck.frame.origin.x -= self.view.frame.width / 2
        duck.frame.origin.y = CGFloat(y)
    }

    @IBAction func ganeRestart(_ sender: UIButton) {

        sender.isHidden = true

        userscore = 0
        timeLeft = 30

        gameStart()

    }


    func  gameStart(){
        duckFly()

       duckTimer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(moveDuck(sender:)), userInfo: nil, repeats: true)
       timeTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateGameTime), userInfo: nil, repeats: true)

    }
}


class Duck: UIImageView {

    var isDuckDead: Bool = false

    var isFalling:Bool = false

}
