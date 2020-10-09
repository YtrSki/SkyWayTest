//
//  ViewController.swift
//  SkyWay Test
//
//  Created by YutaroSakai on 2020/10/04.
//

import UIKit

class ViewController: UIViewController {

    @IBAction func startButton(_ sender: Any) {
        var streamVC = UIStoryboard(name: "StreamViewController", bundle: nil).instantiateViewController(withIdentifier: "streamViewController") as! StreamViewController
        streamVC.modalPresentationStyle = .fullScreen
        self.present(streamVC, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }


}

