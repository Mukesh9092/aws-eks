
# Deployment 

export EKS_STACK_NAME="sdp-eks"
export EKS_AWS_REGION="us-east-1"
export EKS_KEY_PAIR_NAME="sdp-eks-key"

#create key-pair
aws ec2 create-key-pair \
  --region $EKS_AWS_REGION \
  --key-name $EKS_KEY_PAIR_NAME \
  --tag-specifications 'ResourceType=key-pair,Tags=[{Key=Name,Value=eks-key-pair},{Key=Project,Value=aws-eks}]' \
  --output text \
  --query 'KeyMaterial' > $EKS_KEY_PAIR_NAME
  
# Create the EKS Cluster with the following command :

aws cloudformation create-stack --stack-name $EKS_STACK_NAME \
  --region $EKS_AWS_REGION \
  --template-body file://$HOME/aws-eks/infrastructure-as-code/eks-cloudformation.yaml  \
  --capabilities CAPABILITY_NAMED_IAM

# cluster status :

started_date=$(date '+%H:%M:%S')
start=`date +%s`
while true; do 
  if [[ $(aws cloudformation describe-stacks --region $EKS_AWS_REGION --stack-name $EKS_STACK_NAME --query "Stacks[*].StackStatus" --output text) == CREATE_IN_PROGRESS ]]
  then
    echo -e "EKS Cluster status : CREATE IN PROGRESS \n"
    sleep 10
  elif [[ $(aws cloudformation describe-stacks --region $EKS_AWS_REGION --stack-name $EKS_STACK_NAME --query "Stacks[*].StackStatus" --output text) == CREATE_COMPLETE ]]
  then
    echo -e "EKS Cluster status : SUCCESSFULLY CREATED \n"
    end=`date +%s`
    runtime=$((end-start))
    finished_date=$(date '+%H:%M:%S')
    echo "started at :" $started_date 
    echo "finished at :" $finished_date
    hours=$((runtime / 3600)); minutes=$(( (runtime % 3600) / 60 )); seconds=$(( (runtime % 3600) % 60 )); echo "Total time : $hours h $minutes min $seconds sec"
    break
  else
    echo -e "EKS Cluster status : $(aws cloudformation describe-stacks --region $EKS_AWS_REGION --stack-name $EKS_STACK_NAME --query "Stacks[*].StackStatus" --output text) \n"
    break
  fiaws eks \
  --region $EKS_AWS_REGION update-kubeconfig \
  --name $EKS_CLUSTER_NAME

done

# Cluster validation :
aws eks --region $EKS_AWS_REGION describe-cluster \
  --name $EKS_CLUSTER_NAME \
  --query "cluster.status" \
  --output text
# Kubernetes worker node info

kubectl get node

# Kubernetes configuration file
