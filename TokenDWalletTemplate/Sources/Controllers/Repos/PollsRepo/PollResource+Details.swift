import TokenDSDK

extension PollResource {
    
    var subject: SubjectDetails? {
        let details = self.creatorDetails
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: details, options: []) else {
            return nil
        }
        
        guard let subjectDetails = try? JSONDecoder().decode(
            SubjectDetails.self,
            from: jsonData
            ) else { return nil }
        
        return subjectDetails
    }
    
    var choices: Choices? {
        let details = self.creatorDetails
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: details, options: []) else {
            return nil
        }
        
        guard let choicesDetails = try? JSONDecoder().decode(
            Choices.self,
            from: jsonData
            ) else { return nil }
        
        return choicesDetails
    }
    
    var outcome: Outcome? {
        let details = self.creatorDetails
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: details, options: []) else {
            return nil
        }
        
        guard let outcome = try? JSONDecoder().decode(
            Outcome.self,
            from: jsonData
            ) else { return nil }
        
        return outcome
    }
}

extension PollResource {
    
    struct SubjectDetails: Decodable {
        let question: String
    }
    
    struct Choices: Decodable {
        let choices: [ChoiceDetails]
    }
    
    struct ChoiceDetails: Decodable {
        let number: Int
        let description: String
    }
    
    struct Outcome: Decodable {
        let outcome: [String: Int]
    }
}
