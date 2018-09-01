//
//  SDKError.swift
//  SpinCarSDK
//
//  Created by Archil Kuprashvili on 8/28/18.
//

public enum SDKError {
    case NO_ERROR
    case ACCOUNT_LOGIN
    case ACCOUNT_LOAD
    case ACCOUNT_SAVE
    case ACCOUNT_REMOVE
    case SPIN_CREATE
    case SPIN_LOAD
    case SPIN_NOT_EXISTS
    case SPIN_VIN_INVALID
    case SPIN_SAVE
    case SPIN_VIN_DUPLICATE
    case SPIN_REMOVE
    case SPIN_RENAME
    case SPIN_GET_UPLOAD_STATUS
    case SPIN_ASSET_CREATE
    case SPIN_ASSET_UPLOAD
    case SPIN_ASSET_UPLOAD_CANCELLED
    case SPIN_ASSET_NOT_EXISTS
    case SPIN_INVALID_ASSET_PARAMETERS
}
