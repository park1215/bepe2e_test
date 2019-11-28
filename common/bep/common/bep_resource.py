import random
from robot.api import logger

def generateNorwayLegalEntityNumber():
    weights = [3, 2, 7, 6, 5, 4, 3, 2]
    #digits = [9,8,4,6,6,1,1,7]   test pattern - last digit will be 7
    #digits = [8,6,8,5,8,7,2,6]   test pattern where checksum = 10, shortened to 0?
    firstDigit = random.randint(8,9)
    sequence = str(firstDigit)
    sum = firstDigit*weights[0]
    for i in range(7):
        nextDigit = random.randint(0,9)
        sum = sum + int(nextDigit*weights[i+1])
        sequence = sequence + str(nextDigit)
    div = int(sum/11)

    lastDigit = (div+1)*11 - sum
    sequence = sequence + str(lastDigit)[-1]
    return sequence

def numberToString(number):
    number = int(number)
    if number < 10:
        number = str(0) + str(number)
    else:
        number = str(number)
    return number

def stringToInt(inputStr):
    outputStr = str(inputStr)
    outputStr = outputStr.lstrip('0')
    outputInt = int(outputStr)
    return outputInt

def updateProductPidMappingWithSubscriptionCustomerInfo(subscriptionId, ncCustomerRef, productPidMapping):
    for key, value in productPidMapping.items():
        value[4] = subscriptionId
        value[3] = ncCustomerRef
    logger.info(productPidMapping)
    return productPidMapping

def generateNorwayIdentityNumber():
    day = random.randint(1,28)
    day = numberToString(day)
    month = random.randint(1,12)
    month = numberToString(month)
    year = str(random.randint(40,99))
    
    id = year + month + day + str(random.randint(900,999)) + str(31)
    print(id)
    return id

def generateNorwayTin():
    rando = random.randint(1,2)
    if rando == 1:
        tin = generateNorwayLegalEntityNumber()
    else:
        tin = generateNorwayIdentityNumber()
    return 'norway_tin',tin

def generatePolandTin():
    checkDigit = 10
    while checkDigit == 10:  # if modulo is 10, it's not a valid TIN
        weights = [6, 5, 7, 2, 3, 4, 5, 6, 7]
        #prefix_tin = str(random.randint(100000000, 999999999))
        prefix_tin = [random.randint(0, 9) for i in range(9)]
        logger.info("prefix_tin is:")
        logger.info(prefix_tin)
        sequence = [a * b for a, b in zip(weights, prefix_tin)]
        logger.info("sequence is:")
        logger.info(sequence)
        total = sum(sequence)
        logger.info("addition is:")
        logger.info(total)
        checkDigit = total%11
        logger.info("checkDigit is:")
        logger.info(checkDigit)
    prefix_tin.append(checkDigit)
    logger.info("final prefix_tin is:")
    logger.info(prefix_tin)
    strprefix_tin = [str(i) for i in prefix_tin]
    finalSequence = int("".join(strprefix_tin))
    length = len(str(finalSequence))
    if length == 10:
        tin = str(finalSequence)
    else:
        tin = str(finalSequence).zfill(10)

    return 'poland_tin',tin

def generatePolandPesel():
    weights = [1, 3, 7, 9, 1, 3, 7, 9, 1, 3]
    # firstDigit = 9   # yr born between 90-99, first is 9
    # second digit = yr born between 90-99, first is 0-9
    # thirdDigit anf fourth =  month born
    #fifth and sixth = date born
    # 7th to 9th digit any digit form 0-9
    #10th = # sex-male (1,3,5,7,9) female (0,2,4,6,8)
    checkDigit = 0
    while checkDigit == 0:
        thirdDigit = random.randint(0, 1)
        if thirdDigit == 0:
            fourthDigit = random.randint(1, 9)
        else:
            fourthDigit = random.randint(1, 2)
        fifthDigit = random.randint(0, 3)
        if fifthDigit == 0:
            sixthDigit = random.randint(1, 9)
        elif fifthDigit == 1 or fifthDigit == 2:
            sixthDigit = random.randint(0, 9)
        elif fifthDigit == 3:
            sixthDigit = random.randint(0, 1)
        prefix_tin = [9, random.randint(0, 9), thirdDigit, fourthDigit, fifthDigit, sixthDigit, random.randint(0, 9), random.randint(0, 9), random.randint(0, 9), random.randint(0, 9)]
        logger.info("prefix_tin is:")
        logger.info(prefix_tin)
        #prefix_tin = [9, random.randint(0, 9), random.randint(1, 12), random.randint(1, 30), random.randint(0, 9), random.randint(0, 9), random.randint(0, 9), random.randint(0, 9), random.randint(0, 9), random.randint(0, 9)]
        sequence = [a * b for a, b in zip(weights, prefix_tin)]
        logger.info("sequence is:")
        logger.info(sequence)
        total = sum(sequence)
        logger.info("total is:")
        logger.info(total)
        checkDigit = total%10   # to get the last digit of number
        logger.info("checkDigit with modulo 10 is:")
        logger.info(checkDigit)
    lastDigit = 10-checkDigit
    logger.info("lastDigit with minus from 10 is:")
    logger.info(lastDigit)
    prefix_tin.append(lastDigit)
    logger.info("final prefix_tin is:")
    logger.info(prefix_tin)
    strprefix_tin = [str(i) for i in prefix_tin]
    finalSequence = int("".join(strprefix_tin))
    length = len(str(finalSequence))
    if length == 11:
        tin = str(finalSequence)
    else:
        tin = str(finalSequence).zfill(11)
    return 'poland_tin',tin

if __name__ == "__main__":
    generateNorwayLegalEntityNumber()