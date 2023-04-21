//
//  ViewController.swift
//  IrisEyeGlance
//
//  Created by 河野英瑠 on 2022/11/8.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, SYIrisDelegate {
    

    
    @IBOutlet weak var imageview: UIImageView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var leftLavel: UILabel!
    @IBOutlet weak var rightLabel: UILabel!
    @IBOutlet weak var winkLabel: UILabel!
    @IBOutlet weak var wait_Label: UILabel!
    @IBOutlet weak var Num_Label: UILabel!
    @IBOutlet weak var Num_Button: UIButton!
    
    
    @IBAction func Touch_Down(_ sender: Any) {
        num_count += 1
        typeEyeGlance = 0
    }
    
    let camera = Camera()
    let tracker: SYIris = SYIris()!
    
    public let FOCAL_LENGTH: Float = 1304.924438
    public let WIDTH: Float = 1080.0
    public let HEIGHT: Float = 1920.0
    public var frameNum: Int = 0
    
    var array_x : [Float] = []
    var array_y : [Float] = []
    var array_sum_x : [Float] = []
    var array_sum_y : [Float] = []
    var array_ave_x : [Float] = []
    var array_ave_y : [Float] = []
    var max_x : Float = -10
    var max_y : Float = -10
    var min_x : Float = 10
    var min_y : Float = 10
    var max_may_x : Float = -10
    var max_may_y : Float = -10
    var min_may_x : Float = 10
    var min_may_y : Float = 10
    var sum_x : Float = 0
    var sum_y : Float = 0
    var ave5_x : Float = 0
    var ave5_y : Float = 0

    var save_x : Float = 0
    var save_y : Float = 0
    var flag_x : Int = 0
    var flag_y : Int = 0
    var flag_may_x : Float = 0
    var flag_may_y : Float = 0
    var typeEyeGlance : Int = 0
    var wait_txt : String = ""
    
    
    //閾値-----------------------------------------------
    var thr_up_out_may_x : Float = 0.05
    var thr_down_out_may_x : Float = 0.05
    var thr_up_out_vertex_x : Float = 0.05
    var thr_down_out_vertex_x : Float = 0.05
    var thr_up_return_x : Float = 0.04
    var thr_down_return_x : Float = 0.04
    
    //ななめ限定x
    var thrDia_up_out_vertex_x : Float = 0.04
    var thrDia_down_out_vertex_x : Float = 0.04
    
    //yはよく動くからこの値でいいかも
    var thr_up_out_may_y : Float = 0.09
    var thr_down_out_may_y : Float = 0.09
    var thr_up_out_vertex_y : Float = 0.09
    var thr_down_out_vertex_y : Float = 0.09
    var thr_up_return_y : Float = 0.072
    var thr_down_return_y : Float = 0.072
    //閾値終わり-------------------------------------------
    
    var num_count : Int = 0
    var count_x : Int = 0
    var count_y : Int = 0
    var count_begin_x : Int = 0
    var count_begin_y : Int = 0
    var count_end_x : Int = 0
    var count_end_y : Int = 0
    var count_eyeglance : Int = 0
    var count_blink : Int = 0
    var eyeGlance_x : Int = 0
    var eyeGlance_y : Int = 0
    
    
    
    var array_leftIris : [Float] = []
    var array_rightIris : [Float] = []
    var array_sum_leftIris : [Float] = []
    var array_sum_rightIris : [Float] = []
    var add_left : Float = 0
    var add_right : Float = 0
    var sum_leftIris: Float = 0
    var sum_rightIris: Float = 0
    var ave_leftIris: Float = 0
    var ave_rightIris: Float = 0
    
    var leftEyelidHeight: Float = 0.0
    var rightEyelidHeight: Float = 0.0
    var leftEyelidRatio: Float = 0.0
    var rightEyelidRatio: Float = 0.0
    var lrRatio: Float = 0.0
    var leftPrev: Float = -10000.0
    var rightPrev: Float = -10000.0
    var lrDiff: Float = 0.0
    
    //    public let ikichiWink: Float = 0.6
    var winkFlag = 0
    var maxDiff: Float = 0.0
    var peakFrameNum = 0
    var distFrameNum = 0
    var brink = 0
    var brinkFrameNum = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        camera.setSampleBufferDelegate(self)
        camera.start()
        tracker.startGraph()
        tracker.delegate = self
        Num_Label.font = UIFont.systemFont(ofSize: 50)

    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        tracker.processVideoFrame(pixelBuffer)
        
        frameNum += 1
        DispatchQueue.main.async {
            self.imageview.image = UIImage(ciImage: CIImage(cvPixelBuffer: pixelBuffer!))
            self.label.text = "\(self.frameNum)"
        }
    }

    
    func irisTracker(_ irisTracker: SYIris!, didOutputLandmarks landmarks: [Landmark]!) {
        var landmarkAll : [[Float]] = []
        
        
        // matplotlibでのランドマーク位置描画用配列
        //        var xPoints: [Float] = []
        //        var yPoints: [Float] = []
        if let unwrapped = landmarks {
            for (point) in unwrapped {
                landmarkAll.append([point.x, point.y, point.z])
                //                xPoints.append(point.x * WIDTH)
                //                yPoints.append(point.y * HEIGHT)
            }
            //            print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
            //            print(xPoints)
            //            print("?????????????????????????????????????????????")
            //            print(yPoints)
            let leftEyeLandmark = [
                landmarkAll[468],
                landmarkAll[469],
                landmarkAll[470],
                landmarkAll[471],
                landmarkAll[472],
            ]
            let rightEyeLandmark = [
                landmarkAll[473],
                landmarkAll[474],
                landmarkAll[475],
                landmarkAll[476],
                landmarkAll[477],
            ]
            
            // Depthの計算・表示
            let leftIrisSize = caluclateIrisDiamater(landmark: leftEyeLandmark, imageSize: [WIDTH, HEIGHT])
            array_leftIris.append(leftIrisSize)
            let rightIrisSize = caluclateIrisDiamater(landmark: rightEyeLandmark, imageSize: [WIDTH, HEIGHT])
            array_rightIris.append(rightIrisSize)
            let leftDepth_mm = caluclateDepth(centerPoint: leftEyeLandmark[0] , focalLength: FOCAL_LENGTH, irisSize: leftIrisSize, width: WIDTH, height: HEIGHT)
            let rightDepth_mm = caluclateDepth(centerPoint: rightEyeLandmark[0], focalLength: FOCAL_LENGTH, irisSize: rightIrisSize, width: WIDTH, height: HEIGHT)
            
            let leftDepth = Int(round(leftDepth_mm / 10))
            let rightDepth = Int(round(rightDepth_mm / 10))
            let wait = wait_txt
            let num = ["↙︎", "↘︎", "↖︎", "↗︎", "↘︎", "↗︎", "↙︎", "↖︎", "↙︎", "↘︎", "↗︎", "↖︎", "↘︎", "↗︎", "↙︎", "↖︎", "↙︎", "↗︎", "↖︎", "↘︎", "↗︎", "↖︎", "↘︎", "↙︎", "↘︎", "↖︎", "↙︎", "↗︎", "↘︎", "↖︎", "↗︎", "↙︎", "↘︎", "↙︎", "↗︎", "↖︎", "↗︎", "↘︎", "↙︎", "↖︎", "↙︎", "↘︎", "↖︎", "↗︎", "↘︎", "↗︎", "↙︎", "↖︎", "↙︎", "↘︎", "↗︎", "↖︎", "↘︎", "↗︎", "↙︎", "↖︎", "↙︎", "↗︎", "↖︎", "↘︎", "↗︎", "↖︎", "↘︎", "↙︎", "↘︎", "↖︎", "↙︎", "↗︎", "↘︎", "↖︎", "↗︎", "↙︎", "↘︎", "↙︎", "↗︎", "↖︎", "↗︎", "↘︎", "↙︎", "↖︎", "0", "0", "0"]
            let record_num = [6, 4, 8, 2, 4, 2, 6, 8, 6, 4, 2, 8, 4, 2, 6, 8, 6, 2, 8, 4, 2, 8, 4, 6, 4, 8, 6, 2, 4, 8, 2, 6, 4, 6, 2, 8, 2, 4, 6, 8, 6, 4, 8, 2, 4, 2, 6, 8, 6, 4, 2, 8, 4, 2, 6, 8, 6, 2, 8, 4, 2, 8, 4, 6, 4, 8, 6, 2, 4, 8, 2, 6, 4, 6, 2, 8, 2, 4, 6, 8, 0, 0, 0]
            let Touch_num = num[num_count]
            let record_Touch_num = record_num[num_count]
            
            DispatchQueue.main.async {
                self.leftLavel.text = "\(leftDepth)"
                self.rightLabel.text = "\(rightDepth)"
                self.wait_Label.text = "\(wait)"
                self.Num_Label.text = "\(Touch_num)"
                
            }
            
            
            
            //左目虹彩径の処理--------------------------------------------------------------------------------------------------------------------------------
            if array_leftIris.count < 4 {
                sum_leftIris = array_leftIris.reduce(0, +) / Float(array_leftIris.count)
                array_sum_leftIris.append(sum_leftIris)
            } else {
                // LPFの処理
                let isLargestDeviation = abs(array_leftIris[array_leftIris.count - 2] - leftIrisSize) > 1 || abs(array_leftIris[array_leftIris.count - 3] - leftIrisSize) > 1
                if isLargestDeviation {
                    sum_leftIris = array_sum_leftIris[array_sum_leftIris.count - 2]
                } else {
                    sum_leftIris = 0.90 * array_sum_leftIris.last! + 0.10 * leftIrisSize
                }
                // 30ごとに平均を取る
                if array_leftIris.count > 29 {
                    let last30Array_leftIris = array_leftIris[(array_leftIris.count-30)...(array_leftIris.count-1)]
                    let ave_last30_leftIris = last30Array_leftIris.reduce(0, +) / Float(last30Array_leftIris.count)
                    // 平均と乖離していた場合には補正
                    if (abs(array_sum_leftIris.last! - ave_last30_leftIris) > 2.0) {
                        // 直近５つの平均で補正
                        let last5Array_leftIris = array_leftIris[(array_leftIris.count-5)...(array_leftIris.count-1)]
                        let ave_last5_leftIris = last5Array_leftIris.reduce(0, +) / Float(last5Array_leftIris.count)
                        sum_leftIris = ave_last5_leftIris
                    }
                }
                array_sum_leftIris.append(sum_leftIris)
            }
            
            //右目虹彩径の処理-------------------------------------------------------------------------------------------------------------------------------
            if(array_rightIris.count < 4){
                sum_rightIris = 0
                for i in 0...(array_rightIris.count - 1){
                    sum_rightIris += array_rightIris[i]
                }
                sum_rightIris /= (Float)(array_rightIris.count)
                array_sum_rightIris.append(sum_rightIris)
                //4以上の時の処理
            }else{
                //まずはLPFの処理
                if (abs(array_rightIris[array_rightIris.count - 2] - rightIrisSize) > 1 || abs(array_rightIris[array_rightIris.count - 3] - rightIrisSize) > 1){
                    sum_rightIris =  array_sum_rightIris[array_sum_rightIris.count - 2]
                }else{
                    sum_rightIris =  0.90 * (array_sum_rightIris[array_sum_rightIris.count - 1]) + 0.10 * rightIrisSize
                }
                //30ごとに平均を取る
                if(array_rightIris.count > 29){
                    ave_rightIris = 0
                    for i in array_rightIris.count - 30...array_rightIris.count - 1{
                        ave_rightIris += array_rightIris[i]
                    }
                    ave_rightIris /= 30
                    //平均と乖離していた場合には補正
                    if (abs(array_sum_rightIris[array_sum_rightIris.count - 1] - ave_rightIris) > 2.0){
                        //直近５つの平均で補正
                        ave_rightIris = 0
                        for i in array_rightIris.count - 5...array_rightIris.count - 1{
                            ave_rightIris += array_rightIris[i]
                        }
                        ave_rightIris /= 5
                        
                        sum_rightIris = ave_rightIris
                    }
                }
                array_sum_rightIris.append(sum_rightIris)
            }
            //顔の比率の処理---------------------------------------------------------------------------------------------------------------------------------
            
            
            let reference_x = landmarkAll[19][0]
            let reference_y = landmarkAll[19][1]
            let relative_iris_left_x = (landmarkAll[468][0] - reference_x) * 1080
            let relative_iris_left_y = (landmarkAll[468][1] - reference_y) * 1920
            let relative_iris_right_x = (landmarkAll[473][0] - reference_x) * 1080
            let relative_iris_right_y = (landmarkAll[473][1] - reference_y) * 1920
            let per_left_x = relative_iris_left_x / sum_leftIris
            let per_right_x = relative_iris_right_x / sum_rightIris
            let per_left_y = relative_iris_left_y / sum_leftIris
            let per_right_y = relative_iris_right_y / sum_rightIris
            let per_x = (per_left_x + per_right_x) / 2
            let per_y = -(per_left_y + per_right_y) / 2
            array_x.append(per_x)
            array_y.append(per_y)
            
            
            //瞬きした時の処理---------------------------------------------------------------------------------------------------------------------------
            if(array_leftIris.count > 9){
                if(abs(leftIrisSize - array_leftIris[array_leftIris.count - 2]) > 5 ||
                   abs(leftIrisSize - array_leftIris[array_leftIris.count - 3]) > 5 ||
                   abs(leftIrisSize - array_leftIris[array_leftIris.count - 4]) > 5 ||
                   abs(rightIrisSize - array_rightIris[array_rightIris.count - 2]) > 5 ||
                   abs(rightIrisSize - array_rightIris[array_rightIris.count - 3]) > 5 ||
                   abs(rightIrisSize - array_rightIris[array_rightIris.count - 4]) > 5){
                    count_blink = array_leftIris.count//代表として左目のカウントを使う. 瞬きした5フレーム近辺はeyeglance判定しない
                }
            }
            
            //x---------------------------------------------------------------------------------------------------------------------------------------
            //最初の4こは平均を取る
            if(array_x.count < 5){
                ave5_x = 0
                for i in 0...(array_x.count - 1){
                    ave5_x += array_x[i]
                }
                ave5_x /= (Float)(array_x.count)
                array_ave_x.append(ave5_x)//平均の配列
                //上or下に跳ねた時の処理
            }else{
//                if(array_x.count - count_eyeglance > 30){
//                    typeEyeGlance = 0
//                }
                //瞬きをしていなければ常に5ずつ平均を取る。
                if(array_x.count - count_blink < 8 && count_blink != 0){
                    ave5_x = array_ave_x[count_blink - 10]
                    array_ave_x.append(ave5_x)
                }else{
                    ave5_x = 0
                    for i in (array_x.count - 5)...(array_x.count - 1){
                        ave5_x += array_x[i]
                    }
                    ave5_x /= 5
                    array_ave_x.append(ave5_x)
                }
                //!!!!!!!!!0→1飛んでいるかの判定!!!!!!!!!!!!
                if(flag_x == 0){
                    
                    //ワンチャン判定
                    //瞬き判定される直前に関してはワンチャン誤判定の処理で修正できている
                    if(flag_may_x == 0){
                        if(array_x.count - count_blink > 10 ){
                            if((ave5_x - array_ave_x[array_ave_x.count - 10]) > thr_up_out_may_x){//10個差分で閾値を超えた場合
                                count_x = array_x.count - 10//array - 10はふもとギリギリの点
                                count_begin_x = count_x
                                save_x = array_ave_x[count_x - 1]
                                flag_may_x = 1//ワンチャンフラグを上方向へ
                            }else if((array_ave_x[array_ave_x.count - 10] - ave5_x) > thr_down_out_may_x){
                                count_x = array_x.count - 10//array - 10はふもとギリギリの点
                                count_begin_x = count_x
                                save_x = array_ave_x[count_x - 1]
                                flag_may_x = -1//ワンチャンフラグを下方向へ
                            }
                        }
                    }
                    
                    //フラグを1に確定させるか
                    if(flag_may_x != 0 && save_x != 0){
                        //ふもとから15個以内にflag 1判定を入れさせる
                        if((array_x.count - count_x) < 15 && array_x.count - count_end_x > 10){
                            if((ave5_x - save_x) > thr_up_out_vertex_x && flag_may_x == 1){
                                flag_x = 1//flagを1で確定(上方向へ飛んだ)
//                                count_x = array_x.count
                            }else if((save_x - ave5_x) > thr_down_out_vertex_x && flag_may_x == -1){
                                flag_x = -1//flagを-1で確定させる(下方向へ飛んだ)
//                                count_x = array_x.count
                            }
                        //飛びっぱなしの時の修正
                        //15とってもflagが1にならない時
                        }else if(array_x.count - count_x > 15){
                            count_x = array_x.count
                            count_begin_x = 0
                            save_x = 0
                            flag_may_x = 0
                            
                        }
                    }


                    //!!!!!!!!!!!flagを1→0に戻すかどうか!!!!!!!!!!!!!!!
                }else if(flag_x != 0){
                    
                    if(flag_x == 1 && ave5_x > max_x){
                        max_x = ave5_x
                    }else if(flag_x == -1 && ave5_x < min_x){
                        min_x = ave5_x
                    }
                    
                    
                    
                    //上に飛んで戻す時の処理
                    if(15...40 ~= (array_x.count - count_x) && (array_x.count - count_blink) > 20){
                        if(flag_x == 1 && (max_x - ave5_x) > thr_up_return_x && max_x != -10 && ave5_x > array_ave_x[array_ave_x.count - 2] ){//上に飛んだものを戻す
                            flag_x = 0
                            count_x = array_x.count

                            count_end_x = array_x.count
                            eyeGlance_x += 1
                            save_x = 0
                            max_x = -10
                            flag_may_x = 0
                            if(array_x.count - count_eyeglance > 10){
                                if(flag_y == 1){
                                    typeEyeGlance = 4
                                }else if(flag_y == 0){
                                    typeEyeGlance = 3
                                }else if(flag_y == -1){
                                    typeEyeGlance = 2
                                }
                                count_eyeglance = array_x.count
                                count_begin_x = 0
                            }
                        }else if(flag_x == -1 && (ave5_x - min_x) > thr_down_return_x && min_x != 10 && array_ave_x[array_ave_x.count - 2] > ave5_x  ){//下に飛んだものを戻す
                            flag_x = 0
                            count_x = array_x.count

                            count_end_x = array_x.count
                            eyeGlance_x += 1
                            save_x = 0
                            min_x = 10
                            flag_may_x = 0
                            if(array_x.count - count_eyeglance > 10){
                                if(flag_y == 1){
                                    typeEyeGlance = 6
                                }else if(flag_y == 0){
                                    typeEyeGlance = 7
                                }else if(flag_y == -1){
                                    typeEyeGlance = 8
                                }
                                count_eyeglance = array_x.count
                                count_begin_x = 0
                            }
                        }
                        
                    }
                    
                    
                    //flagが1で上にとんだままの時は初期化（eyeglanceはカウントしない）
                    if((array_x.count - count_x) > 40){
                        if(flag_x == 1){
                            flag_x = 0
                            save_x = 0
                            max_x = -10
                            flag_x = 0
                            flag_may_x = 0
                            count_x = array_x.count//現在にすると直後でeyeglanceした時に対応できない
                            count_begin_x = 0
                            count_end_x = array_x.count
                        }else if(flag_x == -1){
                            flag_x = 0
                            save_x = 0
                            min_x = -10
                            flag_x = 0
                            flag_may_x = 0
                            count_x = array_x.count//現在にすると直後でeyeglanceした時に対応できない
                            count_begin_x = 0
                            count_end_x = array_x.count
                        }
                    }
                }
            }
            
            //y---------------------------------------------------------------------------------------------------------------------------------------
            //最初の4こは平均を取る
            if(array_y.count < 5){
                ave5_y = 0
                for i in 0...(array_y.count - 1){
                    ave5_y += array_y[i]
                }
                ave5_y /= (Float)(array_y.count)
                array_ave_y.append(ave5_y)//平均の配列
                //上or下に跳ねた時の処理
            }else{
//                if(array_y.count - count_eyeglance < 10 || array_y.count - count_blink < 20){
//                    wait_txt = "wait"
//                }else{
//                    wait_txt = "go"
//                }
//                if(array_y.count - count_eyeglance > 30){
//                    typeEyeGlance = 0
//                }
                //瞬きをしていなければ常に5ずつ平均を取る。
                if(array_y.count - count_blink < 8 && count_blink != 0){
                    ave5_y = array_ave_y[count_blink - 10]
                    array_ave_y.append(ave5_y)
                }else{
                    ave5_y = 0
                    for i in (array_y.count - 5)...(array_y.count - 1){
                        ave5_y += array_y[i]
                    }
                    ave5_y /= 5
                    array_ave_y.append(ave5_y)
                }
                //!!!!!!!!!0→1飛んでいるかの判定!!!!!!!!!!!!
                if(flag_y == 0){
                    
                    //ワンチャン判定
                    //瞬き判定される直前に関してはワンチャン誤判定の処理で修正できている
                    if(flag_may_y == 0){
                        if(array_y.count - count_blink > 10 ){
                            if((ave5_y - array_ave_y[array_ave_y.count - 10]) > thr_up_out_may_y){//10個差分で閾値を超えた場合
                                count_y = array_y.count - 10//array - 10はふもとギリギリの点
                                count_begin_y = count_y
                                save_y = array_ave_y[count_y - 1]
                                flag_may_y = 1//ワンチャンフラグを上方向へ
                            }else if((array_ave_y[array_ave_y.count - 10] - ave5_y) > thr_down_out_may_y){
                                count_y = array_y.count - 10//array - 10はふもとギリギリの点
                                count_begin_y = count_y
                                save_y = array_ave_y[count_y - 1]
                                flag_may_y = -1//ワンチャンフラグを下方向へ
                            }
                        }
                    }
                    
                    //フラグを1に確定させるか
                    if(flag_may_y != 0 && save_y != 0 && array_y.count - count_end_y > 10){
                        //ふもとから15個以内にflag 1判定を入れさせる
                        if((array_y.count - count_y) < 15){
                            if((ave5_y - save_y) > thr_up_out_vertex_y && flag_may_y == 1){
                                flag_y = 1//flagを1で確定(上方向へ飛んだ)
            //                                count_y = array_y.count
                            }else if((save_y - ave5_y) > thr_down_out_vertex_y && flag_may_y == -1){
                                flag_y = -1//flagを-1で確定させる(下方向へ飛んだ)
            //                                count_y = array_y.count
                            }
                        //15とってもflagが1にならない時
                        //飛びっぱなしの時の修正
                        }else if(array_y.count - count_y > 15){
                            count_y = array_y.count
                            count_begin_y = 0
                            save_y = 0
                            flag_may_y = 0
                        }
                    }


                    //!!!!!!!!!!!flagを0→1に戻すかどうか!!!!!!!!!!!!!!!
                }else if(flag_y != 0){
                    
                    if(flag_y == 1 && ave5_y > max_y){
                        max_y = ave5_y
                    }else if(flag_y == -1 && ave5_y < min_y){
                        min_y = ave5_y
                    }
                    
                    
                    
                    //上に飛んで戻す時の処理
                    if(15...40 ~= (array_y.count - count_y) && (array_y.count - count_blink) > 20){
                        if(flag_y == 1 && (max_y - ave5_y) > thr_up_return_y && max_y != -10 && ave5_y > array_ave_y[array_ave_y.count - 2]){//上に飛んだものを戻す
                            flag_y = 0
                            count_y = array_y.count

                            count_end_y = array_y.count
                            eyeGlance_y += 1
                            save_y = 0
                            max_y = -10
                            flag_may_y = 0

                            if(array_y.count - count_eyeglance > 10){
                                if(flag_x == 1){
                                    typeEyeGlance = 4
                                }else if(flag_x == 0){
                                    if(array_ave_x[count_begin_y - 1] - min_may_x > thrDia_up_out_vertex_x){
                                        typeEyeGlance = 4
                                    }else if(max_x - array_ave_x[count_begin_y - 1] > thrDia_down_out_vertex_x){
                                        typeEyeGlance = 6
                                    }
                                    typeEyeGlance = 5
                                }else if(flag_x == -1){
                                    typeEyeGlance = 6
                                }
                                count_eyeglance = array_y.count
                                count_begin_y = 0
                            }
                        }else if(flag_y == -1 && (ave5_y - min_y) > thr_down_return_y && min_y != 10 && array_ave_y[array_ave_y.count - 2] > ave5_y ){//下に飛んだものを戻す
                            flag_y = 0
                            count_y = array_y.count

                            count_end_y = array_y.count
                            eyeGlance_y += 1
                            save_y = 0
                            min_y = 10
                            flag_may_y = 0
                            if(array_y.count - count_eyeglance > 10){
                                if(flag_x == 1){
                                    typeEyeGlance = 2
                                }else if(flag_x == 0){
                                    if(array_ave_x[count_begin_y - 1] - min_may_x > thrDia_up_out_vertex_x){
                                        typeEyeGlance = 2
                                    }else if(max_x - array_ave_x[count_begin_y - 1] > thrDia_down_out_vertex_x){
                                        typeEyeGlance = 8
                                    }
                                    typeEyeGlance = 1
                                }else if(flag_x == -1){
                                    typeEyeGlance = 8
                                }
                                count_eyeglance = array_y.count
                                count_begin_y = 0
                            }
                        }
                    }
                    
                    
                    //flagが1で上にとんだままの時は初期化（eyeglanceはカウントしない）
                    if((array_y.count - count_y) > 40){
                        if(flag_y == 1){
                            flag_y = 0
                            save_y = 0
                            max_y = -10
                            flag_y = 0
                            flag_may_y = 0
                            count_y = array_y.count//現在にすると直後でeyeglanceした時に対応できない
                            count_begin_y = 0
                            count_end_y = array_y.count
                        }else if(flag_y == -1){
                            flag_y = 0
                            save_y = 0
                            min_y = -10
                            flag_y = 0
                            flag_may_y = 0
                            count_y = array_y.count//現在にすると直後でeyeglanceした時に対応できない
                            count_begin_y = 0
                            count_end_y = array_y.count
                        }
                    }
                }
            }
            print("\(record_Touch_num), \(typeEyeGlance), \(per_x), \(ave5_x), \(count_begin_x), \(count_end_x), \(count_x), \(save_x), \(max_x), \(min_x), \(flag_x), \(flag_may_x), \(per_y), \(ave5_y), \(count_begin_y), \(count_end_y),\(count_y), \(save_y), \(max_y), \(min_y), \(flag_y), \(flag_may_y), \(count_blink)")
        }
    }
    
    
    func irisTracker(_ irisTracker: SYIris!, didOutputPixelBuffer pixelBuffer: CVPixelBuffer!){
        DispatchQueue.main.async {
            self.imageview.image = UIImage(ciImage: CIImage(cvPixelBuffer: pixelBuffer))
        }
    }
}


