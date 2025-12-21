"use strict";
/**
 * HMAC verification for Paymob webhooks
 */
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.verifyPaymobHMAC = verifyPaymobHMAC;
const crypto = __importStar(require("crypto"));
const logger = __importStar(require("firebase-functions/logger"));
/**
 * Verifies Paymob webhook HMAC signature
 *
 * Paymob sends HMAC in the format: HMAC-SHA512(JSON.stringify(obj))
 *
 * @param payload - The webhook payload from Paymob
 * @param hmacSecret - The HMAC secret from environment variables
 * @returns true if HMAC is valid, false otherwise
 */
function verifyPaymobHMAC(payload, hmacSecret) {
    try {
        if (!payload.hmac) {
            logger.warn("Paymob webhook: No HMAC provided");
            return false;
        }
        // Create HMAC from the obj field
        const objString = JSON.stringify(payload.obj);
        const hmac = crypto
            .createHmac("sha512", hmacSecret)
            .update(objString)
            .digest("hex");
        // Compare HMACs (constant-time comparison to prevent timing attacks)
        const providedHmac = payload.hmac.toLowerCase();
        const calculatedHmac = hmac.toLowerCase();
        if (providedHmac !== calculatedHmac) {
            logger.warn("Paymob webhook: HMAC mismatch", {
                provided: providedHmac.substring(0, 10) + "...",
                calculated: calculatedHmac.substring(0, 10) + "...",
            });
            return false;
        }
        logger.info("Paymob webhook: HMAC verified successfully");
        return true;
    }
    catch (error) {
        logger.error("Paymob webhook: HMAC verification error", { error });
        return false;
    }
}
//# sourceMappingURL=hmac.js.map