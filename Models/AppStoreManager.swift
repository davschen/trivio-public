//
//  AppStoreManager.swift
//  Trivio! (iOS)
//
//  Created by David Chen on 11/17/22.
//

import Foundation
import StoreKit

class AppStoreManager: NSObject, ObservableObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    @Published var myProducts = [SKProduct]()
    @Published var transactionState: SKPaymentTransactionState?
    @Published var currentTransactionProductID: String?
    
    var request: SKProductsRequest!
    
    override init() {
        let productIDs = [
            "iOS.Trivio.3.0.Cherry.ASFTP",
            "iOS.Trivio.3.0.Cherry.OTLHT"
        ]
        super.init()
        self.request = SKProductsRequest()
        self.getProducts(productIDs: productIDs)
        SKPaymentQueue.default().add(self)
    }
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        print(response.products)
        if !response.products.isEmpty {
            for fetchedProduct in response.products {
                DispatchQueue.main.async {
                    if fetchedProduct.localizedTitle != "Annual Subscription" {
                        self.myProducts.insert(fetchedProduct, at: 0)
                    } else {
                        self.myProducts.insert(fetchedProduct, at: self.myProducts.endIndex)
                    }
                }
            }
        }
        
        for invalidIdentifier in response.invalidProductIdentifiers {
            print("Invalid identifiers found: \(invalidIdentifier)")
        }
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        print("Request did fail: \(error)")
    }
    
    func getProducts(productIDs: [String]) {
        let request = SKProductsRequest(productIdentifiers: Set(productIDs))
        request.delegate = self
        request.start()
    }
    
    func purchaseProduct(product: SKProduct) {
        if SKPaymentQueue.canMakePayments() {
            let payment = SKPayment(product: product)
            SKPaymentQueue.default().add(payment)
        } else {
            print("User can't make payment.")
        }
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchasing:
                currentTransactionProductID = transaction.payment.productIdentifier
                transactionState = .purchasing
            case .purchased:
                queue.finishTransaction(transaction)
                transactionState = .purchased
            case .restored:
                queue.finishTransaction(transaction)
                transactionState = .restored
            case .failed, .deferred:
                queue.finishTransaction(transaction)
                transactionState = .failed
            default:
                queue.finishTransaction(transaction)
            }
        }
    }
}
