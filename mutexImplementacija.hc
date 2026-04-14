class MyMutex {
  I64 lock_bit;     
  CTask *owner;     
  I64 nested_count; 
};

void MutexInit(MyMutex *m) {
  m->lock_bit = 0;
  m->owner = NULL;
  m->nested_count = 0;
}

void MutexLock(MyMutex *m) {
  CTask *task = Fs; 
  
  if (m->owner == task) {
    m->nested_count++;
    return;
  }

  while (LBts(&m->lock_bit, 0)) {
    Yield;
  }
 
  m->owner = task;
  m->nested_count = 1;
}

void MutexUnlock(MyMutex *m) {
  if (m->owner != Fs) return; 

  m->nested_count--;
  if (m->nested_count == 0) {
    m->owner = NULL;
    LBtr(&m->lock_bit, 0);
  }
}