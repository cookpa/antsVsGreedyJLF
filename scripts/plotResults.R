library(ggplot2)

antsDice = read.csv("antsRegAntsJLFDiceBilateral.csv", row.names = 1)
greedyDice = read.csv("greedyRegGreedyJLFDiceBilateral.csv", row.names = 1)

numLabels = ncol(antsDice)

p = vector("numeric", numLabels)
t = vector("numeric", numLabels)
q = vector("numeric", numLabels)
e = vector("numeric", numLabels)

for (i in 1:numLabels) {
  x = t.test(antsDice[,i], greedyDice[,i], paired = T)
  p[i] = x$p.value
  t[i] = x$statistic
  e[i] = x$estimate
}


for (i in 1:numLabels) {
  x = t.test(antsDiceDouble[,i], antsDice[,i], paired = T)
  p[i] = x$p.value
  t[i] = x$statistic
  e[i] = x$estimate
}

q = p.adjust(p, method = "fdr")

which(q < 0.05)

antsMeans = colMeans(antsDice)
antsSD = apply(antsDice, 2, sd)

greedyMeans = colMeans(greedyDice)
greedySD = apply(greedyDice, 2, sd)

dfBarsAnts = data.frame(Region = factor(colnames(antsDice)), Mean = antsMeans, SD = antsSD, Algorithm = rep("ANTs", numLabels))
dfBarsGreedy = data.frame(Region = factor(colnames(antsDice)), Mean = greedyMeans, SD = greedySD, Algorithm = rep("Greedy", numLabels))

dfBars = rbind(dfBarsAnts, dfBarsGreedy)

ggplot(data=dfBars, aes(x=Region, y=Mean, fill=Algorithm)) +
  geom_bar(stat="identity", position=position_dodge()) +
  scale_fill_brewer(palette="Paired") +
  geom_errorbar(aes(ymin=Mean-SD, ymax=Mean+SD), width=.2, position=position_dodge(.9)) +
  theme_minimal() + coord_flip() + ylab("Mean Dice")
