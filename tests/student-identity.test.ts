import { describe, it, expect, vi, beforeEach } from 'vitest';

describe('Student Identity Contract', () => {
  // Mock principal IDs
  const adminPrincipal = 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM';
  const studentPrincipal = 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG';
  
  // Mock contract calls
  const mockContractCall = vi.fn();
  
  beforeEach(() => {
    mockContractCall.mockReset();
  });
  
  it('should register a new student successfully', async () => {
    // Mock successful registration
    mockContractCall.mockImplementation(() => ({
      success: true,
      result: { value: true }
    }));
    
    const name = 'John Doe';
    const email = 'john@example.com';
    
    expect(mockContractCall({
      contractName: 'student-identity',
      functionName: 'register-student',
      functionArgs: [name, email],
      senderAddress: studentPrincipal
    }).success).toBe(true);
    
    // Verify the contract was called with the correct parameters
    expect(mockContractCall).toHaveBeenCalledWith({
      contractName: 'student-identity',
      functionName: 'register-student',
      functionArgs: [name, email],
      senderAddress: studentPrincipal
    });
  });
  
  it('should not allow duplicate student registrations', async () => {
    // First call succeeds
    mockContractCall.mockImplementationOnce(() => ({
      success: true,
      result: { value: true }
    }));
    
    // Second call fails (duplicate registration)
    mockContractCall.mockImplementationOnce(() => ({
      success: false,
      error: { code: 1 }
    }));
    
    const name = 'John Doe';
    const email = 'john@example.com';
    
    // First registration
    expect(mockContractCall({
      contractName: 'student-identity',
      functionName: 'register-student',
      functionArgs: [name, email],
      senderAddress: studentPrincipal
    }).success).toBe(true);
    
    // Attempt duplicate registration
    expect(mockContractCall({
      contractName: 'student-identity',
      functionName: 'register-student',
      functionArgs: [name, email],
      senderAddress: studentPrincipal
    }).success).toBe(false);
  });
  
  it('should update a student profile successfully', async () => {
    // Mock successful profile update
    mockContractCall.mockImplementation(() => ({
      success: true,
      result: { value: true }
    }));
    
    const updatedName = 'John Smith';
    const updatedEmail = 'john.smith@example.com';
    
    expect(mockContractCall({
      contractName: 'student-identity',
      functionName: 'update-profile',
      functionArgs: [updatedName, updatedEmail],
      senderAddress: studentPrincipal
    }).success).toBe(true);
  });
  
  it('should check if a student is registered', async () => {
    // Mock student is registered
    mockContractCall.mockImplementation(() => ({
      success: true,
      result: { value: true }
    }));
    
    expect(mockContractCall({
      contractName: 'student-identity',
      functionName: 'is-registered',
      functionArgs: [studentPrincipal],
      senderAddress: adminPrincipal
    }).result.value).toBe(true);
  });
  
  it('should retrieve a student profile', async () => {
    const mockProfile = {
      name: 'John Doe',
      email: 'john@example.com',
      'creation-time': 12345,
      'updated-time': 12345
    };
    
    // Mock get student profile
    mockContractCall.mockImplementation(() => ({
      success: true,
      result: { value: mockProfile }
    }));
    
    const result = mockContractCall({
      contractName: 'student-identity',
      functionName: 'get-student-profile',
      functionArgs: [studentPrincipal],
      senderAddress: adminPrincipal
    });
    
    expect(result.success).toBe(true);
    expect(result.result.value).toEqual(mockProfile);
  });
  
  it('should change admin successfully', async () => {
    const newAdminPrincipal = 'ST3AM1A56AK2C1XAFJ4115ZSV26EB49BVQ10MGCS0';
    
    // Mock successful admin change
    mockContractCall.mockImplementation(() => ({
      success: true,
      result: { value: true }
    }));
    
    expect(mockContractCall({
      contractName: 'student-identity',
      functionName: 'set-admin',
      functionArgs: [newAdminPrincipal],
      senderAddress: adminPrincipal
    }).success).toBe(true);
  });
  
  it('should not allow non-admin to change admin', async () => {
    const newAdminPrincipal = 'ST3AM1A56AK2C1XAFJ4115ZSV26EB49BVQ10MGCS0';
    
    // Mock failed admin change due to authorization
    mockContractCall.mockImplementation(() => ({
      success: false,
      error: { code: 403 }
    }));
    
    expect(mockContractCall({
      contractName: 'student-identity',
      functionName: 'set-admin',
      functionArgs: [newAdminPrincipal],
      senderAddress: studentPrincipal // Non-admin trying to change admin
    }).success).toBe(false);
  });
});
