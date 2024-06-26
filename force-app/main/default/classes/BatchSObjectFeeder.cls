global class BatchSObjectFeeder implements Iterator<SObject>, Iterable<SObject> {
    SObject[] source;
    
    global Iterator<SObject> iterator() {
        return this;
    }
    
    global BatchSObjectFeeder(SObject[] source) {
        this.source = source;
    }
    
    global SObject next() {
        // List is destructive for efficiency
        return source.remove(0);
    }
    
    global boolean hasNext() {
        return source != null && !source.isempty();
    }
}