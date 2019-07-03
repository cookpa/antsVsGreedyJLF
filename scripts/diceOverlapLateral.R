library(ANTsR)

## labelList should be leftLabelID,LeftLabelName,RightLabelID,RightLabelName
diceOverlap = function(groundTruthSeg, candidateSeg, labelList) {

  # Number of bilateral labels, where Left and Right versions exist for each
  numLabels = nrow(labelList)
  
  
  resultLabels = c()
  
  # List of column names for results, combined left / right
  resultLabelsBilateral = c()

  for (i in 1:numLabels) {
    leftInd = 2*(i-1)+1
    rightInd = 2*i
    resultLabels[leftInd] = as.character(labelList[i,2])
    resultLabels[rightInd] = as.character(labelList[i,4])
    
    tokens = unlist(strsplit(as.character(labelList[i,2]), split="[.]"))
    resultLabelsBilateral[i] = paste(tokens[2:length(tokens)], collapse = ".")
  }
  
  resultDF = data.frame(matrix(nrow = 1, ncol = length(resultLabels)))
  resultDFBilateral = data.frame(matrix(nrow = 1, ncol = length(resultLabelsBilateral)))
  
  colnames(resultDF) = resultLabels
  colnames(resultDFBilateral) = resultLabelsBilateral

  for (i in 1:numLabels) {
    leftGT = 1 * (groundTruthSeg == labelList[i,1])
    leftCandidate = 1 * (candidateSeg == labelList[i,1])
    
    intersection = leftGT * leftCandidate
    
    diceLeft = 2 * sum(intersection) / (sum(leftGT) + sum(leftCandidate))
    
    rightGT = groundTruthSeg == labelList[i,3]
    rightCandidate = candidateSeg == labelList[i,3]
    
    intersection = rightGT * rightCandidate
    
    diceRight = 2 * sum(intersection) / (sum(rightGT) + sum(rightCandidate))
  
    resultDFBilateral[1,i] = mean(c(diceLeft, diceRight))
    
    resultDF[1, 1 + 2*(i - 1)] = diceLeft
    resultDF[1, 2*i] = diceRight
    
  }
    
  return(list(results = resultDF, resultsBilateralMerged = resultDFBilateral))
  
}

subjects = c("1000", "1001", "1002", "1006", "1007", "1008", "1009", "1010", "1011", "1012", "1013", "1014", "1015", "1036", "1017", "1003", "1004", "1005", 
             "1018", "1019", "1101", "1104", "1107", "1110", "1113", "1116", "1119", "1122", "1125", "1128")

numSubj = length(subjects)

antsJLF = list()
greedyJLF = list()
groundTruth = list()

for (i in 1:numSubj) {
  antsJLF[[i]] = antsImageRead( paste("results/antsRegAntsJLF/", subjects[i], "Labels.nii.gz", sep = "") )
  greedyJLF[[i]] = antsImageRead( paste("results/greedyRegGreedyJLF/", subjects[i], "Labels.nii.gz", sep = "") )
  groundTruth[[i]] = antsImageRead( paste("groundTruth/", subjects[i], "_3_seg.nii.gz", sep = "") )
}

labelList = read.csv("mindBoggleNonIgnoreBilateral.csv")

numLabels = nrow(labelList)

antsDice = data.frame()
greedyDice = data.frame()

antsDiceBilateral =  data.frame()
greedyDiceBilateral = data.frame()

for (i in 1:numSubj) {
  print(paste("Processing subject", subjects[i]))
  
  subjectANTsResults = diceOverlap(groundTruth[[i]], antsJLF[[i]], labelList)
  subjectGreedyResults = diceOverlap(groundTruth[[i]], greedyJLF[[i]], labelList)
  
  antsDice = rbind(antsDice, subjectANTsResults[[1]])
  greedyDice = rbind(greedyDice, subjectGreedyResults[[1]])
 
  antsDiceBilateral = rbind(antsDiceBilateral, subjectANTsResults[[2]])
  greedyDiceBilateral = rbind(greedyDiceBilateral, subjectGreedyResults[[2]])
}

row.names(antsDice) = subjects
row.names(greedyDice) = subjects

write.csv(antsDice, "stats/antsRegAntsJLFDice.csv")
write.csv(greedyDice, "stats/greedyRegGreedyJLFDice.csv")

row.names(antsDiceBilateral) = subjects
row.names(greedyDiceBilateral) = subjects

write.csv(antsDiceBilateral, "stats/antsRegAntsJLFDiceBilateral.csv")
write.csv(greedyDiceBilateral, "stats/greedyRegGreedyJLFDiceBilateral.csv")
