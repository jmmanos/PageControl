//
//  ViewController.swift
//  PageControl
//
//  Created by John Manos on 2/9/17.
//  Copyright © 2017 John Manos. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIScrollViewDelegate {
    @IBOutlet weak var snakePageControl: PageControl!
    @IBOutlet weak var fillPageControl: PageControl!
    @IBOutlet weak var scrollPageControl: PageControl!
    @IBOutlet weak var scalePageControl: PageControl!
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let page = scrollView.contentOffset.x / scrollView.bounds.width
        let progressInPage = scrollView.contentOffset.x - (page * scrollView.bounds.width)
        let progress = CGFloat(page) + progressInPage
        snakePageControl.progress = progress
        fillPageControl.progress = progress
        scrollPageControl.progress = progress
        scalePageControl.progress = progress
    }
}
