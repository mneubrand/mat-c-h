--[[
/**
Global object to manage "in app purchase".
Some of the call trigger the events "transactionUpdate" event and the "storeProductInfo".
These event have the field "name" and one of the other field defined below, check the one that 
is not nil to manage the corresponding transaction status.

(Only the specified values are of type number, all of the others are string)

event 
{
	name = "transactionUpdate",
	
	--error status
	error = --optional possible values are: "QIENT_INVALID", "PAYMENT_INVALID", "PAYMENT_NOT_ALLOWED", "UNKNOWN_ERROR"
	
	--canceled status
	canceled = --optional possible values are: "PAYMENT_CANCELLED"
	
	--pending status
	pending = --optional possible values are: "Please wait...". 
	
	--purchased status
	--optional fields returned on a successful purchase
	purchased = product id
	quantity = quantity of purchased products having this id
	transactionId = the id of this transaction
	
	--restored status
	--optional fields returned on a products restore
	restored = product id
	quantity = quantity
	transactionId = the id of this transaction
	originalTransactionId = the original transaction with which the product was purchased
}


event 
{
	name = "storeProductInfo",
	
	--error status
	error = --optional possible values are: "NO_CONNECTION", "RESTORE_FAILED", "NOT_FOUND", "UNKNOWN_STATUS"
	
	
	--purchased status
	--optional fields returned on a successful purchase
	purchased = product id
	quantity = (number) quantity of purchased products having this id
	transactionId = the id of this transaction
	
	--restored status
	--optional fields returned on a products restore
	restored = product id
	
	--info received status
	--optional fields returned after successfully receiving product info 
	productId =  the id of the product requested
	formattedPrice = the proce in formatted currency
	description = the description of the product
	title = the title of the product
	priceLocale = the local of the price
	price = (number) the numeric value of the price
}


*/
--]]
appStore = {}

--[[
/**
Checks if the app store system is available.
@return true if the app store system is available, false otherwise.
*/
--]]
function appStore:isAvailable()
	return quick.QAppStore:isAvailable()
end

--[[
/**
Starts the app store system.
@return true on success, false otherwise.
*/
--]]
function appStore:start()
	return quick.QAppStore:start()
end

--[[
/**
Starts a product info request. This call triggers the "transactionUpdate" event and the "storeProductInfo" event.
@param prodId the id of the product
@return true on success, false otherwise
*/
--]]
function appStore:requestProductInfo(prodId)
	return quick.QAppStore:requestProductInfo(prodId)
end

--[[
/**
Starts a product purchase. This call triggers the "transactionUpdate" event and the "storeProductInfo" event.
@param prodId the id of the product
@param quantity the quantity of the product.
@return true on success, false otherwise
*/
--]]
function appStore:startProductPurchase(prodId, quantity)
	return quick.QAppStore:startProductPurchase(prodId, quantity)
end

--[[
/**
Restore previously purchased products. Useful if the app is reinstalled o installed to another device.
This call triggers the "transactionUpdate" event and the "storeProductInfo" event.
@return true on success, false otherwise.
*/
--]]
function appStore:restoreProducts()
	return quick.QAppStore:restoreProducts()
end

--[[
/**
Checks if the current user is enabled to make payment with the current device.
@return true if it is enabled to make payment, false otherwise.
*/
--]]
function appStore:canMakePayment()
	return quick.QAppStore:canMakePayment()
end

--[[
/**
Checks if the billing system has been initialized.
@return true if it has been initialized, false otherwise
*/
--]]
function appStore:hasStarted()
	return quick.QAppStore:hasStarted()
end
