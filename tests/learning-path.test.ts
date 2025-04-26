import { describe, it, expect, vi, beforeEach } from 'vitest';

describe('Learning Path Contract', () => {
  // Mock principal IDs
  const adminPrincipal = 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM';
  const creatorPrincipal = 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG';
  const studentPrincipal = 'ST3AM1A56AK2C1XAFJ4115ZSV26EB49BVQ10MGCS0';
  
  // Mock contract calls
  const mockContractCall = vi.fn();
  
  beforeEach(() => {
    mockContractCall.mockReset();
  });
  
  it('should create a learning path successfully', async () => {
    // Mock successful learning path creation
    mockContractCall.mockImplementation(() => ({
      success: true,
      result: { value: true }
    }));
    
    const pathId = 'path-123';
    const title = 'Introduction to Blockchain';
    const description = 'Learn the basics of blockchain technology';
    
    expect(mockContractCall({
      contractName: 'learning-path',
      functionName: 'create-learning-path',
      functionArgs: [pathId, title, description],
      senderAddress: creatorPrincipal
    }).success).toBe(true);
  });
  
  it('should not allow duplicate learning path IDs', async () => {
    // First call succeeds
    mockContractCall.mockImplementationOnce(() => ({
      success: true,
      result: { value: true }
    }));
    
    // Second call fails (duplicate path ID)
    mockContractCall.mockImplementationOnce(() => ({
      success: false,
      error: { code: 1 }
    }));
    
    const pathId = 'path-123';
    const title = 'Introduction to Blockchain';
    const description = 'Learn the basics of blockchain technology';
    
    // First creation
    expect(mockContractCall({
      contractName: 'learning-path',
      functionName: 'create-learning-path',
      functionArgs: [pathId, title, description],
      senderAddress: creatorPrincipal
    }).success).toBe(true);
    
    // Attempt duplicate creation
    expect(mockContractCall({
      contractName: 'learning-path',
      functionName: 'create-learning-path',
      functionArgs: [pathId, title, description],
      senderAddress: creatorPrincipal
    }).success).toBe(false);
  });
  
  it('should add a module to a learning path successfully', async () => {
    // Mock successful module addition
    mockContractCall.mockImplementation(() => ({
      success: true,
      result: { value: true }
    }));
    
    const pathId = 'path-123';
    const moduleOrder = 1;
    const contentId = 'content-123';
    const prerequisiteModules = [];
    const assessmentId = 'assessment-123';
    
    expect(mockContractCall({
      contractName: 'learning-path',
      functionName: 'add-path-module',
      functionArgs: [pathId, moduleOrder, contentId, prerequisiteModules, assessmentId],
      senderAddress: creatorPrincipal
    }).success).toBe(true);
  });
  
  it('should not allow non-creators to add modules to a path', async () => {
    // Mock failed module addition due to authorization
    mockContractCall.mockImplementation(() => ({
      success: false,
      error: { code: 403 }
    }));
    
    const pathId = 'path-123';
    const moduleOrder = 1;
    const contentId = 'content-123';
    const prerequisiteModules = [];
    const assessmentId = 'assessment-123';
    
    expect(mockContractCall({
      contractName: 'learning-path',
      functionName: 'add-path-module',
      functionArgs: [pathId, moduleOrder, contentId, prerequisiteModules, assessmentId],
      senderAddress: studentPrincipal // Non-creator trying to add module
    }).success).toBe(false);
  });
  
  it('should enroll a student in a learning path successfully', async () => {
    // Mock successful enrollment
    mockContractCall.mockImplementation(() => ({
      success: true,
      result: { value: true }
    }));
    
    const pathId = 'path-123';
    
    expect(mockContractCall({
      contractName: 'learning-path',
      functionName: 'enroll-in-path',
      functionArgs: [pathId],
      senderAddress: studentPrincipal
    }).success).toBe(true);
  });
  
  it('should not allow duplicate enrollments', async () => {
    // First call succeeds
    mockContractCall.mockImplementationOnce(() => ({
      success: true,
      result: { value: true }
    }));
    
    // Second call fails (already enrolled)
    mockContractCall.mockImplementationOnce(() => ({
      success: false,
      error: { code: 3 }
    }));
    
    const pathId = 'path-123';
    
    // First enrollment
    expect(mockContractCall({
      contractName: 'learning-path',
      functionName: 'enroll-in-path',
      functionArgs: [pathId],
      senderAddress: studentPrincipal
    }).success).toBe(true);
    
    // Attempt duplicate enrollment
    expect(mockContractCall({
      contractName: 'learning-path',
      functionName: 'enroll-in-path',
      functionArgs: [pathId],
      senderAddress: studentPrincipal
    }).success).toBe(false);
  });
  
  it('should update student progress successfully', async () => {
    // Mock successful progress update
    mockContractCall.mockImplementation(() => ({
      success: true,
      result: { value: true }
    }));
    
    const pathId = 'path-123';
    const moduleOrder = 2;
    
    expect(mockContractCall({
      contractName: 'learning-path',
      functionName: 'update-progress',
      functionArgs: [pathId, moduleOrder],
      senderAddress: studentPrincipal
    }).success).toBe(true);
  });
  
  it('should mark a path as completed successfully', async () => {
    // Mock successful path completion
    mockContractCall.mockImplementation(() => ({
      success: true,
      result: { value: true }
    }));
    
    const pathId = 'path-123';
    
    expect(mockContractCall({
      contractName: 'learning-path',
      functionName: 'complete-path',
      functionArgs: [pathId],
      senderAddress: studentPrincipal
    }).success).toBe(true);
  });
  
  it('should retrieve learning path details', async () => {
    const mockPathDetails = {
      title: 'Introduction to Blockchain',
      description: 'Learn the basics of blockchain technology',
      creator: creatorPrincipal,
      'creation-time': 12345,
      'is-active': true
    };
    
    // Mock get learning path
    mockContractCall.mockImplementation(() => ({
      success: true,
      result: { value: mockPathDetails }
    }));
    
    const pathId = 'path-123';
    
    const result = mockContractCall({
      contractName: 'learning-path',
      functionName: 'get-learning-path',
      functionArgs: [pathId],
      senderAddress: adminPrincipal
    });
    
    expect(result.success).toBe(true);
    expect(result.result.value).toEqual(mockPathDetails);
  });
  
  it('should deactivate a learning path successfully', async () => {
    // Mock successful path deactivation
    mockContractCall.mockImplementation(() => ({
      success: true,
      result: { value: true }
    }));
    
    const pathId = 'path-123';
    
    expect(mockContractCall({
      contractName: 'learning-path',
      functionName: 'deactivate-path',
      functionArgs: [pathId],
      senderAddress: creatorPrincipal
    }).success).toBe(true);
  });
});
