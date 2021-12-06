To ensure that an autoscaling nodegroup will scale from zero, first manually scale it up, run a job on it and allow it to scale back down. 
The next time you run a job on the group autoscaling should work. 
However if you just create the autoscaling group with 0 volume and try to run a job on it it may fail. 
