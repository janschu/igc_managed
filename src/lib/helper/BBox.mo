module {
    // BBox
    public type BBox = {
        minLat: Float;
        minLon: Float;
        maxLat: Float;
        maxLon: Float;
    };

    //extend the BBox 
    public func extendBBox (boxA: BBox, boxB: BBox) : BBox {
        let minLa = if (boxA.minLat < boxB.minLat) {boxA.minLat} else {boxB.minLat};
        let maxLa = if (boxA.maxLat > boxB.maxLat) {boxA.maxLat} else {boxB.maxLat};
        let minLo = if (boxA.minLon < boxB.minLon) {boxA.minLon} else {boxB.minLon};
        let maxLo = if (boxA.maxLon > boxB.maxLon) {boxA.maxLon} else {boxB.maxLon};
        return {minLat = minLa; maxLat = maxLa; minLon = minLo; maxLon = maxLo};
    };  
};